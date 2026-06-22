import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_box.dart';
import '../providers/auth_provider.dart';

/// Email + password login for cashier/admin users.
class CashierLoginScreen extends StatefulWidget {
  const CashierLoginScreen({super.key});

  @override
  State<CashierLoginScreen> createState() => _CashierLoginScreenState();
}

class _CashierLoginScreenState extends State<CashierLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      UiHelpers.showInfo(context, 'Email dan password wajib diisi.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().loginCashier(
        email: _email.text.trim(),
        password: _password.text,
      );
      // Remove the pushed login (and role) routes so the root gate — now
      // showing the cashier shell — becomes visible.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        leading: AppBackButton(),
        title: Text('Masuk Kasir'),
      ),
      content: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoLabel(
                  label: 'Email',
                  child: AppTextBox(
                    controller: _email,
                    placeholder: 'kasir@toko.test',
                    prefixIcon: FluentIcons.mail,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 16),
                InfoLabel(
                  label: 'Password',
                  child: AppPasswordBox(
                    controller: _password,
                    placeholder: 'Password',
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: ProgressRing(strokeWidth: 2),
                          )
                        : const Text('Masuk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
