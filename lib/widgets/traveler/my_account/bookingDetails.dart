import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/modele_booking_details.dart';
import 'package:chicaparts_partner/models/traveler/modele_review.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Branche ces imports vers TES services/modèles
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with SingleTickerProviderStateMixin {
  final api = ApiBooking();
  final _apiReview = ApiReview();

  late Future<OneBookingDetails> _future; // <-- crée un modèle "BookingDetails"
  late TabController _tab;

  User? _currentUser;
  Review? _myReview;
  bool _loadingReview = true;

  var lang;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);

    _init();
  }

  /// Charge le currentUser puis les détails
  Future<void> _init() async {
    await _loadUserForReview();
    setState(() {
      _future = _load(); // maintenant user est dispo
    });
  }

  /// Rafraîchit les détails après un update de review
  Future<void> _refreshDetails() async {
    if (_currentUser == null) return;
    setState(() {
      _future = _load();
    });
    await _future;
  }

  /// Charge les détails en utilisant le currentUser
  Future<OneBookingDetails> _load() async {
    if (_currentUser == null) {
      throw Exception("Connection required");
    }
    return api.getOneBooking(widget.bookingId, _currentUser!);
  }

  /// Charge le user local
  Future<void> _loadUserForReview() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null) {
      _currentUser = null;
      _loadingReview = false;
      return;
    }

    _currentUser = User.fromJson(jsonDecode(userJson));
  }

  Future<void> _checkExistingReview(OneBookingDetails d) async {
    if (_currentUser == null) {
      setState(() => _loadingReview = false);
      return;
    }
    try {
      final r = await _apiReview.getUserReviewForAccommodation(
        customerId: _currentUser!.id,
        accommodationId: int.tryParse(d.accommodationId) ?? 0,
      );
      setState(() {
        _myReview = r;
        _loadingReview = false;
      });
    } catch (_) {
      setState(() => _loadingReview = false);
    }
  }

  Future<void> _submitReview({
    required OneBookingDetails d,
    required int confort,
    required int staf,
    required int facilities,
    required int cleanliness,
    required String comment,
  }) async {
    if (_currentUser == null) return;
    final base = Review(
      id: 0,
      customerId: _currentUser!.id,
      accommodationId: int.tryParse(d.accommodationId) ?? 0,
      reviewer: _currentUser!.name,
      comment: comment,
      confort: confort,
      staf: staf,
      facilities: facilities,
      cleanliness: cleanliness,
      score: 0, accommodation: null, // côté backend append
    );
    try {
      Review saved;
      if (_myReview == null) {
        saved = await _apiReview.createReview(base);
      } else {
        saved = await _apiReview.updateReview(_myReview!.id, base);
      }
      _checkExistingReview(d);
      setState(() => _myReview = saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review save. Thanks !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review error')),
      );
    }
  }

  Future<void> _deleteMyReview() async {
    if (_myReview == null) return;
    try {
      await _apiReview.deleteReview(_myReview!.id);
      setState(() => _myReview = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error')),
      );
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Widget _reviewSection(OneBookingDetails d) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // si pas connecté
    if (_currentUser == null) {
      return CardSection(
        title: "Avis",
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lang.t('booking_connect_text')),
        ),
      );
    }

    if (_loadingReview) {
      return CardSection(
        title: lang.t('review'),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
      );
    }

    // si avis existant -> affiche carte + actions
    if (_myReview != null) {
      final r = _myReview!;
      return CardSection(
        title: lang.t('your_review'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingLine(label: lang.t('comfort'), value: r.confort),
            RatingLine(label: lang.t('staf'), value: r.staf),
            RatingLine(label: lang.t('amenities'), value: r.facilities),
            RatingLine(label: lang.t('cleanliness'), value: r.cleanliness),
            const SizedBox(height: 8),
            ExpandableComment(
              text: r.comment,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    // ouvre un petit éditeur avec les valeurs actuelles
                    final edited = await showDialog<ReviewFormData>(
                      context: context,
                      builder: (_) => ReviewDialog(
                        initial: ReviewFormData(
                          confort: r.confort,
                          staf: r.staf,
                          facilities: r.facilities,
                          cleanliness: r.cleanliness,
                          comment: r.comment,
                        ),
                      ),
                    );
                    if (edited != null) {
                      _submitReview(
                        d: d,
                        confort: edited.confort,
                        staf: edited.staf,
                        facilities: edited.facilities,
                        cleanliness: edited.cleanliness,
                        comment: edited.comment,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(lang.t('update')),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _deleteMyReview,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(lang.t('delete'),
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      );
    }

    // sinon -> formulaire création
    return CardSection(
      title: lang.t('give_feedback'),
      child: ReviewForm(
        onSubmit: (data) => _submitReview(
          d: d,
          confort: data.confort,
          staf: data.staf,
          facilities: data.facilities,
          cleanliness: data.cleanliness,
          comment: data.comment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 En-tête personnalisée
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF244B6B), size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lang.t('booking_details'),
                    style: const TextStyle(
                      color: Color(0xFF244B6B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 Onglets (TabBar)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tab,
                isScrollable: true,
                indicatorColor: const Color(0xFF244B6B),
                labelColor: const Color(0xFF244B6B),
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: lang.t('booking')),
                  Tab(text: lang.t('useful_info')),
                  Tab(text: lang.t('Check-in_Check-out')),
                  Tab(text: lang.t('accommodation')),
                ],
              ),
            ),

            // 🔹 Contenu dynamique
            Expanded(
              child: FutureBuilder<OneBookingDetails>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(child: Text(lang.t('error_network')));
                  }

                  final d = snapshot.data!;

                  if (_currentUser != null && _loadingReview) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _checkExistingReview(d);
                    });
                  }

                  return TabBarView(
                    controller: _tab,
                    children: [
                      _ReservationTab(
                        d: d,
                        lang: lang,
                        reviewBuilder: () => _reviewSection(d),
                      ),
                      _UsefulInfoTab(
                        d: d,
                        lang: lang,
                      ),
                      _AccessTab(
                        d: d,
                        lang: lang,
                      ),
                      _AccommodationTab(
                        d: d,
                        lang: lang,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Onglet 1 : Réservation ----------
class _ReservationTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  final Widget Function()? reviewBuilder; // 👈 optionnel
  const _ReservationTab(
      {required this.d, required this.lang, this.reviewBuilder});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM yyyy');
    final range =
        "${f.format(d.firstNight)} → ${f.format(d.lastNight.add(const Duration(days: 1)))}";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CardSection(
          title: lang.t('stay_information'),
          child: _twoCols(
            left: InfoColumn(items: [
              InfoRow(lang.t('stay_date'), range, boldValue: true),
              InfoRow(lang.t('duration'), "${d.nights} nuit(s)"),
            ]),
            right: InfoColumn(items: [
              InfoRow(lang.t('travelers'), d.travelersLabel, boldValue: true),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        CardSection(
          title: lang.t('status_information'),
          child: _twoCols(
            left: InfoColumn(items: [
              InfoHeader(lang.t('booking')),
              InfoRow(lang.t('booking_date'),
                  DateFormat('dd MMM yyyy – HH:mm').format(d.createdAt)),
              InfoRowGlobal(lang.t('payment_status'), d.paymentStatusLabel,
                  badgeColor: d.paymentStatusColor),
              InfoRow(lang.t('amount_paid'),
                  "${NumberFormat('#,##0').format(d.paidAmount)} ${d.currency}"),
              InfoRow(lang.t('reference'), d.reference ?? "N/A"),
              InfoRow("Source", d.source),
            ]),
            right: InfoColumn(items: [
              const InfoHeader("Client"),
              InfoRow(lang.t('full_name'), d.guestFullName, boldValue: true),
              InfoRow(lang.t('email'), d.guestEmail),
              InfoRow(lang.t('phone'), d.guestPhone),
              InfoRow(lang.t('address'), d.guestAddress ?? "—"),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        CardSection(
          title: lang.t('payment_sommary'),
          child: InfoColumn(items: [
            MoneyRow(lang.t('base_price'), d.price, d.currency),
            MoneyRow(lang.t('cleaning_fees'), d.cleaningFee, d.currency),
            MoneyRow(lang.t('chicaparts_fees'), d.serviceFee, d.currency),
            MoneyRow(lang.t('city_taxe'), d.tax, d.currency),
            const Divider(),
            MoneyRow(lang.t('total_price'), d.total, d.currency, bold: true),
          ]),
        ),
        const SizedBox(height: 12),
        if (reviewBuilder != null) reviewBuilder!(),
      ],
    );
  }
}

// ---------- Onglet 2 : Infos utiles ----------
class _UsefulInfoTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  const _UsefulInfoTab({
    required this.d,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // 1 col <560px, 2 colonnes <900px, 3 colonnes au-delà
        final cols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);

        final sections = <Widget>[
          _InfoSection(
            title: lang.t('wifi_access'),
            children: const [],
            rows: [
              InfoRow(lang.t('wifi_identifier'), d.wifiSsid ?? "—",
                  boldValue: true),
              InfoRow(lang.t('password'), d.wifiPassword ?? "—",
                  boldValue: true),
            ],
          ),
          _InfoSection(
            title: lang.t('accessibility'),
            rows: [
              InfoRow(lang.t('floor_number'), d.floor ?? "—"),
              InfoRow(lang.t('door_number'), d.door ?? "—"),
            ],
          ),
          _InfoSection(
            title: lang.t('parking'),
            rows: [
              InfoRow(lang.t('parking_type'), d.parkingType ?? "—",
                  boldValue: true),
              InfoRow(lang.t('location'), d.parkingLocation ?? "—",
                  boldValue: true),
              InfoRow(lang.t('access_method'), d.parkingAccess ?? "—"),
              InfoRow(lang.t('parking_spot'), d.parkingSlot ?? "—"),
            ],
          ),
          // Décommente si tu ajoutes ces champs côté modèle
          // _InfoSection(
          //   title: "Équipements",
          //   rows: [
          //     InfoRow("Chauffage", d.heating ?? "—"),
          //     InfoRow("Eau chaude", d.hotWater ?? "—"),
          //     InfoRow("Plaque", d.stove ?? "—"),
          //     InfoRow("Machine à café", d.coffeeMachine ?? "—"),
          //   ],
          // ),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardSection(
              title: lang.t('useful_info'),
              child: _ResponsiveColumns(children: sections, columns: cols),
            ),
            const SizedBox(height: 12),
            CardSection(
              title: lang.t('house_rules'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final rule in d.houseRules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text("• $rule"),
                    ),
                  const SizedBox(height: 12),
                  InfoHeader(lang.t('timetable')),
                  InfoRow(lang.t('check-in'), d.checkinTime ?? "—",
                      boldValue: true),
                  InfoRow(lang.t('check-out'), d.checkoutTime ?? "—",
                      boldValue: true),
                  InfoRow(lang.t('quiet_hours'), d.quietHours ?? "—"),
                  if (d.specificRules.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InfoHeader(lang.t('additional_rules')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: d.specificRules
                          .map((e) => Chip(label: Text(e)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------- Onglet 3 : Accès & sortie ----------
class _AccessTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  const _AccessTab({required this.d, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CardSection(
          title: lang.t('check-in_instructions'),
          child: SelectableText(d.accessInstructions ?? "—"),
        ),
        const SizedBox(height: 12),
        CardSection(
          title: lang.t('check-out_instructions'),
          child: SelectableText(d.checkoutInstructions ?? "—"),
        ),
      ],
    );
  }
}

// ---------- Onglet 4 : Hébergement ----------
class _AccommodationTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  const _AccommodationTab({required this.d, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CardSection(
          title: d.accommodationTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.accommodationImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(d.accommodationImage!),
                ),
              const SizedBox(height: 12),
              InfoColumn(items: [
                InfoRow(lang.t('capacity'), d.capacityLabel ?? "—"),
                InfoRow(lang.t('total_space'), d.surfaceLabel ?? "—"),
                InfoRow("Type", d.typeLabel ?? "—"),
                InfoRow(lang.t('entire_place'),
                    d.isEntirePlace ? lang.t('yes') : lang.t('no')),
                InfoRow(lang.t('desabled_access'),
                    d.isAccessible ? lang.t('yes') : lang.t('no')),
              ]),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {
                    if (d.accommodationId != null) {
                      Navigator.pushNamed(
                        context,
                        '/accommodation/${d.accommodationId}/${d.currency}/${d.price}',
                      );
                    }
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: Text(lang.t('view_all_details')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Colonnage responsive (évite les overflow)
class _ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  const _ResponsiveColumns({required this.children, required this.columns});

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: children
            .map((w) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: w))
            .toList(),
      );
    }
    final spacing = 16.0;
    final totalSpacing = spacing * (columns - 1);
    final width = (MediaQuery.of(context).size.width - totalSpacing - 32) /
        columns; // -32 padding card

    return Wrap(
      spacing: spacing,
      runSpacing: 12,
      children: children.map((w) => SizedBox(width: width, child: w)).toList(),
    );
  }
}

/// Petit wrapper visuel pour une “sous-carte” de la section
class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget>? children;
  final List<InfoRow> rows;
  const _InfoSection({required this.title, this.children, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoHeader(title),
        ...rows,
        if (children != null) ...children!,
      ],
    );
  }
}

/// == MISE À JOUR d’InfoRow ==
///  - largeur fixe pour le label (évite “lignes verticales”)
///  - la valeur wrap dans l’espace restant
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;
  const InfoRow(this.label, this.value, {this.boldValue = false});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: Colors.grey[700], height: 1.2);
    final valueStyle = TextStyle(
      fontWeight: boldValue ? FontWeight.w600 : FontWeight.w400,
      height: 1.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // <- clé : colonne label stable
            child: Text(label, style: labelStyle, softWrap: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre de sous-section (inchangé si tu as déjà cette classe)
class InfoHeader extends StatelessWidget {
  final String text;
  const InfoHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

Widget _twoCols({required Widget left, required Widget right}) {
  return LayoutBuilder(
    builder: (context, c) {
      final narrow = c.maxWidth < 360; // ajuste 360–400 selon ton design
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    },
  );
}
