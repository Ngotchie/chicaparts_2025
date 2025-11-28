import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/modele_review.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/tips/tip_payment_processing_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AppUI {
  static const primary = Color(0xFF244B6B);
  static const kpiYellow = Color(0xFFF8D84E);
  static const kpiBlue = Color(0xFF2D9CDB);
  static const kpiPurple = Color(0xFF8E44AD);

  static BorderRadius get radius => BorderRadius.circular(14);
  static double get cardElevation => 1.5;

  static BoxShadow get softShadow => BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 6),
      );

  static TextStyle get title => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      );
}

class HeaderCompact extends StatelessWidget {
  final bool isGuest;
  final String? userName;
  final String? email;
  final VoidCallback onEdit;
  final VoidCallback onLogin;
  final VoidCallback onCompleteProfile;
  final VoidCallback onLater;
  final bool showBanner;

  const HeaderCompact({
    super.key,
    required this.isGuest,
    required this.userName,
    required this.email,
    required this.onEdit,
    required this.onLogin,
    required this.onCompleteProfile,
    required this.onLater,
    required this.showBanner,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne avatar + infos + action
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF244B6B),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGuest
                            ? lang.t('guest')
                            : (userName ?? lang.t('user')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      if (!isGuest && email != null && email!.isNotEmpty)
                        Text(
                          email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                isGuest
                    ? FilledButton(
                        onPressed: onLogin,
                        child: Text(lang.t('login')),
                      )
                    : TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(lang.t('update')),
                      ),
              ],
            ),

            // Bannière compacte (optionnelle)
            if (showBanner) ...[
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFE8EEF4),
                      child: Icon(Icons.account_circle,
                          color: Color(0xFF244B6B), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang.t('update_profile_text'),
                        style: const TextStyle(fontSize: 13, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        FilledButton.icon(
                          onPressed: onCompleteProfile,
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(lang.t('completed')),
                          style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8)),
                        ),
                        TextButton(
                          onPressed: onLater,
                          child: Text(lang.t('completed_late')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MiniStatsRow extends StatelessWidget {
  final int reservations;
  final int favorites;
  final int reviews;

  const MiniStatsRow({
    super.key,
    required this.reservations,
    required this.favorites,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final caption = TextStyle(fontSize: 12, color: Colors.grey[600]);
    const valueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: IntrinsicHeight(
        // pour aligner les diviseurs éventuellement
        child: Row(
          children: [
            _MiniStatInline(
              icon: Icons.event_available,
              value: reservations.toString(),
              label: lang.t('book...'),
              iconColor: const Color(0xFFB8860B),
              valueStyle: valueStyle,
              captionStyle: caption,
            ),
            _MiniStatDivider(),
            _MiniStatInline(
              icon: Icons.favorite_border,
              value: favorites.toString(),
              label: lang.t('favorite'),
              iconColor: const Color(0xFF1E88E5),
              valueStyle: valueStyle,
              captionStyle: caption,
            ),
            _MiniStatDivider(),
            _MiniStatInline(
              icon: Icons.reviews,
              value: reviews.toString(),
              label: lang.t('review'),
              iconColor: const Color(0xFF7E57C2),
              valueStyle: valueStyle,
              captionStyle: caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatInline extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final TextStyle valueStyle;
  final TextStyle captionStyle;

  const _MiniStatInline({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.valueStyle,
    required this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: valueStyle),
              Text(label, style: captionStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 24, // espace latéral total
      thickness: 1,
      color: Colors.grey[300],
    );
  }
}

class MiniStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color bg;
  final Color fg;

  const MiniStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: bg,
              child: Icon(icon, color: fg, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppUI.radius,
        boxShadow: [AppUI.softShadow],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (color ?? AppUI.primary).withOpacity(.12),
            child: Icon(icon, color: color ?? AppUI.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: AppUI.caption),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700))),
          if (actionLabel != null && onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(foregroundColor: AppUI.primary),
            ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status; // "pending" | "confirmed" | "cancelled" | etc.
  const StatusChip({super.key, required this.status});

  Color _bg() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFEDE7FE);
      case 'confirmed':
        return const Color(0xFFE7F7EF);
      case 'cancelled':
        return const Color(0xFFFFE9E8);
      default:
        return const Color(0xFFEFF3F7);
    }
  }

  Color _fg() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF6C3CF0);
      case 'confirmed':
        return const Color(0xFF1B8E4B);
      case 'cancelled':
        return const Color(0xFFD74A4A);
      default:
        return const Color(0xFF385168);
    }
  }

  String _label(lang) {
    switch (status.toLowerCase()) {
      case 'pending':
        return lang.t('waitting');
      case 'confirmed':
        return lang.t('confirmed');
      case 'cancelled':
        return lang.t('cancelled');
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(20)),
      child: Text(_label(lang),
          style: TextStyle(
              color: _fg(), fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class BookingTile extends StatelessWidget {
  final String title;
  final String city;
  final String dates;
  final String status;
  final String? imageUrl;
  final VoidCallback? onTap;

  const BookingTile({
    super.key,
    required this.title,
    required this.city,
    required this.dates,
    required this.status,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppUI.radius,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppUI.radius,
          boxShadow: [AppUI.softShadow],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl == null
                  ? Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(Icons.photo_size_select_actual_outlined,
                          color: Colors.grey),
                    )
                  : Image.network(imageUrl!.replaceFirst("http://", "https://"),
                      width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(Icons.home_work_outlined,
                          size: 14, color: Colors.grey),
                      Text(city, style: AppUI.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: AppUI.title),
                  const SizedBox(height: 4),
                  Text(dates, style: AppUI.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  QuickAction(this.icon, this.label, this.onTap);
}

class QuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  const QuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: actions.map((a) => _QuickCard(a)).toList(),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final QuickAction action;
  const _QuickCard(this.action);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: AppUI.radius,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppUI.radius,
          boxShadow: [AppUI.softShadow],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppUI.primary.withOpacity(.1),
              child: Icon(action.icon, color: AppUI.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(action.label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class SectionSpacer extends StatelessWidget {
  final double height;
  const SectionSpacer({super.key, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFFF2F4F7), // fond gris très léger
    );
  }
}

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(thickness: 1, color: Colors.grey.shade300),
    );
  }
}

class CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  const CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoHeader extends StatelessWidget {
  final String text;
  const InfoHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Colors.grey[700])),
      );
}

class InfoRowGlobal extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;
  final Color? badgeColor;
  const InfoRowGlobal(this.label, this.value,
      {this.boldValue = false, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    final v = boldValue
        ? Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
        : Text(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          const SizedBox(width: 12),
          badgeColor == null
              ? v
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor!.withOpacity(.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(value,
                      style: TextStyle(
                          color: badgeColor, fontWeight: FontWeight.w700)),
                ),
        ],
      ),
    );
  }
}

class MoneyRow extends StatelessWidget {
  final String label;
  final num amount;
  final String currency;
  final bool bold;
  const MoneyRow(this.label, this.amount, this.currency, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final text = "${NumberFormat('#,##0').format(amount)} $currency";
    return InfoRowGlobal(
      label,
      text,
      boldValue: bold,
    );
  }
}

class InfoColumn extends StatelessWidget {
  final List<Widget> items;
  const InfoColumn({required this.items});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: items);
}

class ReviewFormData {
  int confort;
  int staf;
  int facilities;
  int cleanliness;
  String comment;
  ReviewFormData({
    this.confort = 3,
    this.staf = 3,
    this.facilities = 3,
    this.cleanliness = 3,
    this.comment = '',
  });
}

class ReviewForm extends StatefulWidget {
  final void Function(ReviewFormData data) onSubmit;
  const ReviewForm({required this.onSubmit});
  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _data = ReviewFormData();
  final _formKey = GlobalKey<FormState>();

  Widget _slider(String label, int value, ValueChanged<int> onChanged) {
    final remaining = (5 - value).clamp(0, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + valeur actuelle (X/5)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF244B6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "$value/5",
                style: const TextStyle(
                  color: Color(0xFF244B6B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        // Curseur avec indicateur de valeur
        SliderTheme(
          data: const SliderThemeData(
              showValueIndicator: ShowValueIndicator.always),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: "$value",
            onChanged: (v) => onChanged(v.round()),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Column(
      children: [
        _slider(lang.t('comfort'), _data.confort,
            (v) => setState(() => _data.confort = v)),
        _slider(
            lang.t('staf'), _data.staf, (v) => setState(() => _data.staf = v)),
        _slider(lang.t('amenities'), _data.facilities,
            (v) => setState(() => _data.facilities = v)),
        _slider(lang.t('cleanliness'), _data.cleanliness,
            (v) => setState(() => _data.cleanliness = v)),
        const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: TextFormField(
            minLines: 3,
            maxLines: 6,
            onChanged: (t) => _data.comment = t,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? lang.t('comment_required')
                : null,
            decoration: InputDecoration(
              labelText: lang.t('your_comment'),
              alignLabelWithHint: true, // Important pour les champs multiline
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState?.validate() != true) return;
              widget.onSubmit(_data);
            },
            icon: const Icon(Icons.send),
            label: Text(lang.t('send')),
          ),
        )
      ],
    );
  }
}

class ReviewDialog extends StatefulWidget {
  final ReviewFormData initial;
  const ReviewDialog({required this.initial});
  @override
  State<ReviewDialog> createState() => ReviewDialogState();
}

class ReviewDialogState extends State<ReviewDialog> {
  late ReviewFormData _data;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _data = ReviewFormData(
      confort: widget.initial.confort,
      staf: widget.initial.staf,
      facilities: widget.initial.facilities,
      cleanliness: widget.initial.cleanliness,
      comment: widget.initial.comment,
    );
  }

  Widget _slider(String label, int initial, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: initial.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: "$initial",
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return AlertDialog(
      title: Text(lang.t('update_review')),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _slider(lang.t('comfort'), _data.confort,
                (v) => setState(() => _data.confort = v)),
            _slider(lang.t('staf'), _data.staf,
                (v) => setState(() => _data.staf = v)),
            _slider(lang.t('amenities'), _data.facilities,
                (v) => setState(() => _data.facilities = v)),
            _slider(lang.t('cleanliness'), _data.cleanliness,
                (v) => setState(() => _data.cleanliness = v)),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: TextFormField(
                initialValue: _data.comment,
                decoration: InputDecoration(
                  labelText: lang.t('your_comment'),
                  border: const OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
                onChanged: (t) => _data.comment = t,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? lang.t('comment_required')
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancelled'))),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(context, _data);
          },
          child: Text(lang.t('save')),
        ),
      ],
    );
  }
}

class RatingLine extends StatelessWidget {
  final String label;
  final int value;
  const RatingLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label)),
          const SizedBox(width: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < value ? Icons.star : Icons.star_border,
                size: 18,
                color: const Color(0xFFFFC107),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ExpandableComment extends StatefulWidget {
  final String text;
  final int maxLines;
  const ExpandableComment({
    super.key,
    required this.text,
    this.maxLines = 5,
  });

  @override
  State<ExpandableComment> createState() => _ExpandableCommentState();
}

class _ExpandableCommentState extends State<ExpandableComment> {
  bool _expanded = false;
  late String _text;
  @override
  void initState() {
    super.initState();
    _text = widget.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final textWidget = Text(
      _text,
      maxLines: _expanded ? null : widget.maxLines,
      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
    );

    final showToggle = _text.split('\n').length > widget.maxLines ||
        _text.length > 200; // seuil ajustable

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget,
        if (showToggle)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 25),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _expanded ? lang.t('show_less') : lang.t('show_more'),
              style: const TextStyle(
                color: Color(0xFF244B6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class ReservationInProgressCard extends StatelessWidget {
  final String title;
  final String city; // "Omnisport, Yaoundé, Cameroon"
  final DateTime firstNight;
  final DateTime lastNight; // inclusif ou exclusif selon ton modèle
  final String currency; // "FCFA", "EUR"…
  final num totalAmount;
  final int travelers; // ex: 1 (on ne l’affiche plus mais on garde la data)
  final String paymentStatus; // "paid"|"unpaid"|"partial"
  final String statusLabel; // "En attente", "Confirmée"…
  final String? imageUrl;

  final VoidCallback onChangeDates;
  final VoidCallback onTip; // (non utilisé dans la version light, mais dispo)
  final VoidCallback onReview; // idem
  final VoidCallback onMore; // utilisé comme "Voir les détails"

  const ReservationInProgressCard({
    super.key,
    required this.title,
    required this.city,
    required this.firstNight,
    required this.lastNight,
    required this.currency,
    required this.totalAmount,
    required this.travelers,
    required this.paymentStatus,
    required this.statusLabel,
    this.imageUrl,
    required this.onChangeDates,
    required this.onTip,
    required this.onReview,
    required this.onMore,
  });

  Color get _statusColor {
    switch (paymentStatus) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'partial':
        return const Color(0xFFF9A825);
      default:
        return const Color(0xFFD32F2F); // Rouge doux pour impayé / en attente
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final nf = NumberFormat('#,##0');
    final df = DateFormat('dd MMM yyyy');
    final endInc = lastNight; // adapte si lastNight est exclusif

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFE08A), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.t('active_booking'),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              _Badge(text: statusLabel, color: _statusColor),
            ],
          ),
          const SizedBox(height: 10),

          // Bloc principal compact
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: imageUrl == null
                      ? Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 30),
                        )
                      : Image.network(
                          imageUrl!.replaceFirst("http://", "https://"),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Infos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Ville
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dates + montant sur une seule ligne
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined,
                                  size: 16, color: Colors.black87),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${df.format(firstNight)} – ${df.format(endInc)}",
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Montant total
                        Text(
                          "${nf.format(totalAmount)} $currency",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        // Statut paiement
                        Text(
                          paymentStatus == 'paid'
                              ? lang.t('paid')
                              : paymentStatus == 'partial'
                                  ? lang.t('partial')
                                  : lang.t('unpaid'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Actions minimalistes
          Row(
            children: [
              Expanded(
                child: _PillButton.filled(
                  icon: Icons.arrow_forward_ios_rounded,
                  label: lang.t('details'),
                  onTap: onMore, // 👉 ouvre la page détails
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillButton.outlined(
                  icon: Icons.calendar_month_outlined,
                  label: lang.t('update'),
                  onTap: onChangeDates,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Tu peux garder tes anciennes classes _Badge et _PillButton
class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color? fg;
  final Color? bg;
  final Color? border;

  const _PillButton._({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
    this.fg,
    this.bg,
    this.border,
  });

  factory _PillButton.filled({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      _PillButton._(
        icon: icon,
        label: label,
        onTap: onTap,
        filled: true,
      );

  factory _PillButton.outlined({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? fg,
    Color? bg,
    Color? border,
  }) =>
      _PillButton._(
        icon: icon,
        label: label,
        onTap: onTap,
        filled: false,
        fg: fg,
        bg: bg,
        border: border,
      );

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF244B6B);

    if (filled) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primary.withOpacity(.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fgColor = fg ?? primary;
    final borderColor = border ?? fgColor.withOpacity(.35);
    final bgColor = bg ?? fgColor.withOpacity(.03);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SyncReservationsWidget extends StatefulWidget {
  final ApiBooking api;
  final User user;

  const SyncReservationsWidget({
    required this.api,
    required this.user,
  });

  @override
  State<SyncReservationsWidget> createState() => SyncReservationsWidgetState();
}

class SyncReservationsWidgetState extends State<SyncReservationsWidget> {
  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  bool otpSent = false;
  bool loading = false;
  int? expiresIn;

  // ---------------------------------------
  // STEP 1 : Envoi du code OTP
  // ---------------------------------------
  void sendOtp() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('enter_mail'))),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await widget.api.requestSyncOtp(
        user: widget.user,
        email: email,
      );

      expiresIn = res["expires_in"];
      setState(() => otpSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${lang.t('expire_text')} $expiresIn minutes."),
        ),
      );
    } catch (e) {
      // Affiche le message d’erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );

      // Ferme la fenêtre après un léger délai (permet d'afficher le SnackBar)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Navigator.pop(context);
      });
    }

    setState(() => loading = false);
  }

  // ---------------------------------------
  // STEP 2 : Validation OTP + synchro
  // ---------------------------------------
  void validateOtp() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final email = emailCtrl.text.trim();
    final code = otpCtrl.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('enter_otp'))),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await widget.api.confirmSync(
        user: widget.user,
        email: email,
        code: code,
      );

      final synced = res["synced_count"] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$synced ${lang.t('resa_sync')}"),
        ),
      );

      Navigator.pop(context); // Fermer le bottom sheet
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) Navigator.pop(context);
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('sync_my_resa'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            lang.t('sync_from'),
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // EMAIL
          TextField(
            controller: emailCtrl,
            readOnly: otpSent,
            decoration: InputDecoration(
              labelText: "Email",
              isDense: true, // rend le champ plus compact
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey, // couleur fixe
                  width: 1, // bordure fine
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey, // pas de changement de couleur
                  width: 1,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),

              // Pour readOnly
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Colors.grey,
                  width: 1,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // OTP
          if (otpSent)
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: lang.t('otp_code'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(
                otpSent ? lang.t('validate_code') : lang.t('Receive_code'),
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
              ),
              onPressed: loading ? null : (otpSent ? validateOtp : sendOtp),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class TipWidget extends StatefulWidget {
  final Booking booking;
  const TipWidget({required this.booking});

  @override
  State<TipWidget> createState() => _TipWidgetState();
}

class _TipWidgetState extends State<TipWidget> {
  final customCtrl = TextEditingController();
  int? selectedAmount;

  List<int> quickTips = [];

  @override
  void initState() {
    super.initState();

    // Récupération devise utilisateur via Provider
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);

    final currency = currencyProvider.currency; // "EUR", "XAF", "USD"
    final total = widget.booking.price ?? 0;

    // Calcul des tips : 5%, 10%, 15%
    final tip5 = (total * 0.05).round();
    final tip10 = (total * 0.10).round();
    final tip15 = (total * 0.15).round();

    quickTips = [tip5, tip10, tip15];
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);

    final currency = currencyProvider.currency; // "EUR", "XAF", "USD"
    final symbol = currency == "XAF" ? "FCFA" : currency;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('stay_end'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF244B6B),
            ),
          ),

          const SizedBox(height: 10),
          Text(
            lang.t('tip_thank_text'),
            style: TextStyle(color: Colors.grey[700]),
          ),

          const SizedBox(height: 20),

          // 🔹 Montants rapides adaptés à la devise
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: quickTips.map((amount) {
              final isSelected = selectedAmount == amount;
              return GestureDetector(
                onTap: () => setState(() => selectedAmount = amount),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF244B6B) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$amount $symbol",
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 🔹 Montant personnalisé
          TextField(
            controller: customCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "${lang.t('custom_amount')} ($symbol)",
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(width: 1, color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(width: 1, color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Bouton valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final value =
                    selectedAmount ?? int.tryParse(customCtrl.text.trim());

                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.t('enter_valid_amount')),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                _sendTip(context, widget.booking, value, currency);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                lang.t('send_tip'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _sendTip(
    BuildContext context,
    Booking booking,
    int amount,
    String currency,
  ) {
    final symbol = currency == "XAF" ? "FCFA" : currency;

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    // Construire un petit label pour le séjour
    String stayLabel;
    try {
      final first = DateTime.parse(booking.firstNight);
      final last = DateTime.parse(booking.lastNight);
      final fmt = DateFormat('dd MMM yyyy');
      stayLabel =
          "${lang.t('stay_from')} ${fmt.format(first)} ${lang.t('to')} ${fmt.format(last)}";
    } catch (_) {
      stayLabel = "Séjour récent";
    }

    // Email du client → tu peux adapter selon ton modèle
    final customerEmail = booking.guestFirstName ?? "";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TipPaymentProcessingPage(
          amount: amount.toDouble(),
          currency: symbol, // "FCFA" / "EUR" / "USD"
          customerEmail: customerEmail,
          bookingId: booking.id,
          stayLabel: stayLabel,
        ),
      ),
    );
  }
}
