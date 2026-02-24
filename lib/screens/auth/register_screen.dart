import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedSexe = "M";
  String _selectedPathologie = "Non spécifié";
  bool _isSmoker = false;
  bool _obscurePassword = true;

  final List<String> _pathologies = [
    "Non spécifié", "Asthme", "BPCO", "Pneumonie", "Infection"
  ];

  static const Color _primary      = Color(0xFF1565C0);
  static const Color _primaryLight = Color(0xFF1E88E5);
  static const Color _accent       = Color(0xFF00ACC1);
  static const Color _bgPage       = Color(0xFFF0F5FB);
  static const Color _cardBg       = Colors.white;
  static const Color _fieldFill    = Color(0xFFF4F8FD);
  static const Color _borderColor  = Color(0xFFD0E4F7);
  static const Color _textDark     = Color(0xFF0D1F3C);
  static const Color _textMid      = Color(0xFF4A6887);
  static const Color _textLight    = Color(0xFF8BAABF);

  late AnimationController _anim;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 750));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 80),
        () { if (mounted) _anim.forward(); });
  }

  @override
  void dispose() {
    for (final c in [_nomController, _prenomController, _emailController,
      _passwordController, _dobController, _heightController, _weightController])
      c.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.post("/register", {
        "nom": _nomController.text.trim(),
        "prenom": _prenomController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "date_naissance": _dobController.text,
        "sexe": _selectedSexe,
        "taille_cm": int.parse(_heightController.text),
        "poids_kg": double.parse(_weightController.text),
        "pathologie": _selectedPathologie,
        "est_fumeur": _isSmoker,
      });
      if (!mounted) return;
      if (response.statusCode == 200) {
        _toast("Compte créé ! L'IA est calibrée.", const Color(0xFF2E7D32),
            Icons.check_circle_outline_rounded);
        Navigator.pop(context);
      } else {
        _toast("Email déjà utilisé ou données invalides.", const Color(0xFFE53935),
            Icons.error_outline_rounded);
      }
    } catch (_) {
      _toast("Erreur de connexion au serveur.", const Color(0xFFE53935),
          Icons.wifi_off_rounded);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              collapsedHeight: 64,
              pinned: true,
              elevation: 0,
              backgroundColor: _primary,
              leading: Padding(
                padding: const EdgeInsets.all(10),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
                collapseMode: CollapseMode.parallax,
              ),
              title: Text('Créer un profil',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              centerTitle: true,
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 550),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProgressBadge(),
                          const SizedBox(height: 24),
                          _sectionTitle(
                              '1', 'Identité', Icons.person_outline_rounded,
                              const Color(0xFF1E88E5)),
                          const SizedBox(height: 12),
                          _card(children: [
                            Row(children: [
                              Expanded(child: _field(_prenomController, 'Prénom',
                                  Icons.badge_outlined)),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_nomController, 'Nom',
                                  Icons.person_outline)),
                            ]),
                            const SizedBox(height: 16),
                            Row(children: [
                              Expanded(child: _datePicker()),
                              const SizedBox(width: 12),
                              Expanded(child: _sexeDropdown()),
                            ]),
                          ]),
                          const SizedBox(height: 20),
                          _sectionTitle('2', 'Données médicales',
                              Icons.monitor_heart_outlined,
                              const Color(0xFF00ACC1)),
                          const SizedBox(height: 12),
                          _card(children: [
                            Row(children: [
                              Expanded(child: _field(_heightController,
                                  'Taille (cm)', Icons.height_rounded,
                                  type: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_weightController,
                                  'Poids (kg)', Icons.monitor_weight_outlined,
                                  type: TextInputType.number)),
                            ]),
                            const SizedBox(height: 16),
                            _pathoDropdown(),
                            const SizedBox(height: 16),
                            _smokerTile(),
                          ]),
                          const SizedBox(height: 20),
                          _sectionTitle('3', 'Identifiants de connexion',
                              Icons.shield_outlined, const Color(0xFF7B1FA2)),
                          const SizedBox(height: 12),
                          _card(children: [
                            _field(_emailController, 'Adresse e-mail',
                                Icons.email_outlined,
                                type: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _passwordFieldWidget(),
                          ]),
                          const SizedBox(height: 32),
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                      color: _primary, strokeWidth: 2.5))
                              : _ctaButton(),
                          const SizedBox(height: 20),
                          _rgpdBanner(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.05),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.20),
                          blurRadius: 16, offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/images/logo11.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.air_rounded,
                                size: 34, color: Colors.white),
                          )),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SmartBreath',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          )),
                      const SizedBox(height: 4),
                      Text('Créez votre profil de santé',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          )),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 5),
                            Text('Calibrage IA · XGBoost',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFD7F5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_outlined,
              color: _primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 étapes · ~2 minutes',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    )),
                Text('Identité · Données médicales · Compte',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _textMid,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_outlined,
                color: _primary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String num, String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(num,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textDark,
            )),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(.4), color.withOpacity(.0)],
                ),
                borderRadius: BorderRadius.circular(2),
              )),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(.06),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          readOnly: readOnly,
          onTap: onTap,
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: _textDark,
              fontWeight: FontWeight.w500),
          validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null,
          decoration: _inputDeco(icon: icon),
        ),
      ],
    );
  }

  Widget _datePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Date de naissance'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: _textDark, fontWeight: FontWeight.w500),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: _primary),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(() => _dobController.text =
                  picked.toString().split(' ')[0]);
            }
          },
          decoration: _inputDeco(
              icon: Icons.calendar_today_outlined,
              suffix: const Icon(Icons.edit_calendar_outlined,
                  color: _textLight, size: 16)),
        ),
      ],
    );
  }

  Widget _sexeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Sexe'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedSexe,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _textLight, size: 20),
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: _textDark, fontWeight: FontWeight.w500),
          decoration: _inputDeco(icon: Icons.wc_outlined),
          items: const [
            DropdownMenuItem(value: "M", child: Text("Homme")),
            DropdownMenuItem(value: "F", child: Text("Femme")),
          ],
          onChanged: (v) => setState(() => _selectedSexe = v!),
        ),
      ],
    );
  }

  Widget _pathoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Pathologie principale'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedPathologie,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _textLight, size: 20),
          isExpanded: true,
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: _textDark, fontWeight: FontWeight.w500),
          decoration:
              _inputDeco(icon: Icons.medical_information_outlined),
          items: _pathologies.map((p) =>
              DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => _selectedPathologie = v!),
        ),
      ],
    );
  }

  Widget _smokerTile() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: _isSmoker
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isSmoker
              ? Colors.orange.withOpacity(.45)
              : _borderColor,
          width: 1.4,
        ),
      ),
      child: SwitchListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text('Je suis fumeur(euse)',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isSmoker
                  ? Colors.orange.shade800
                  : _textDark,
            )),
        subtitle: Text(
            "L'IA calibre ses seuils d'alerte selon ce paramètre",
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: _textLight,
            )),
        value: _isSmoker,
        activeColor: Colors.orange,
        secondary: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _isSmoker
                ? Colors.orange.withOpacity(.12)
                : _fieldFill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.smoking_rooms_rounded,
              color: _isSmoker ? Colors.orange : _textLight,
              size: 20),
        ),
        onChanged: (v) => setState(() => _isSmoker = v),
      ),
    );
  }

  Widget _passwordFieldWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Mot de passe'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: _textDark, fontWeight: FontWeight.w500),
          validator: (v) =>
              v!.length < 6 ? 'Minimum 6 caractères' : null,
          decoration: _inputDeco(
            icon: Icons.lock_outline_rounded,
            suffix: GestureDetector(
              onTap: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textLight, size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 12, color: _textLight),
          const SizedBox(width: 5),
          Text('Minimum 6 caractères recommandés',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: _textLight)),
        ]),
      ],
    );
  }

  Widget _ctaButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(.40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20),
            const SizedBox(width: 10),
            Text('VALIDER MON PROFIL',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 1.0,
                )),
          ],
        ),
      ),
    );
  }

  Widget _rgpdBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_outlined,
                color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vos données sont chiffrées et strictement confidentielles. Elles ne sont jamais partagées à des tiers.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF2E7D32),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textMid,
          letterSpacing: .2,
        ));
  }

  InputDecoration _inputDeco({required IconData icon, Widget? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: _fieldFill,
      prefixIcon: Icon(icon, color: const Color(0xFF5BA3CC), size: 18),
      suffixIcon: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12),
              child: suffix)
          : null,
      suffixIconConstraints:
          const BoxConstraints(minWidth: 32, minHeight: 32),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BoxSide(color: _borderColor, width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFFE53935), width: 1.8),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 10.5),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      isDense: true,
    );
  }
}
