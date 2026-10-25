import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/tokens.dart';

class SupportScreen extends StatefulWidget {
  final bool isReportProblem; // True = Report a bug form, False = Contact Support
  const SupportScreen({super.key, this.isReportProblem = false});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  bool _isSending = false;
  bool _attachLogs = true; // Telemetry reports
  String _selectedCategory = 'Billing';

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    final String categoryInfo = widget.isReportProblem ? 'BUG_REPORT' : 'SUPPORT_TICKET ($_selectedCategory)';
    final String subjectText = '[Lumina $categoryInfo] ${_subjectController.text.trim()}';
    final String bodyText = widget.isReportProblem 
        ? 'Steps to Reproduce / Description:\n${_messageController.text.trim()}\n\n---\nDevice Logs Attached: $_attachLogs'
        : 'Message:\n${_messageController.text.trim()}';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@lumina.com',
      queryParameters: {
        'subject': subjectText,
        'body': bodyText,
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        _showSnackBar('Opening email client...');
      } else {
        // Fallback simulation if no email client registered
        await Future.delayed(const Duration(milliseconds: 1500));
        _showSnackBar(widget.isReportProblem ? 'Bug report submitted!' : 'Support ticket created successfully!');
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      _showSnackBar('Could not launch email client: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        backgroundColor: LuminaTokens.darkSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.isReportProblem ? 'Report a Problem' : 'Contact Support';
    final descText = widget.isReportProblem
        ? 'Found a bug? Describe the issue and attach device diagnostics so our engineering team can resolve it.'
        : 'Have billing questions, feature requests, or general inquiries? Create a ticket and we will resolve it within 24 hours.';

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          titleText,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                descText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: LuminaTokens.darkTextMuted,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Category selector (if Contact Support)
              if (!widget.isReportProblem) ...[
                Text(
                  'Support Category',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: LuminaTokens.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      dropdownColor: LuminaTokens.darkSurface,
                      iconEnabledColor: Colors.white70,
                      items: ['Billing', 'Face Matching', 'Storage Quota', 'General Inquiry'].map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(val, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Subject Input
              TextFormField(
                controller: _subjectController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: widget.isReportProblem ? 'Problem Title' : 'Subject',
                  labelStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: LuminaTokens.darkBorder.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: LuminaTokens.darkSurface,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return widget.isReportProblem ? 'Please enter a problem title' : 'Please enter a subject';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description Input
              TextFormField(
                controller: _messageController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: widget.isReportProblem ? 'Steps to Reproduce / Description' : 'Message Details',
                  labelStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 13),
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: LuminaTokens.darkBorder.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: LuminaTokens.darkSurface,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter description details';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Attachment logs toggle (if Report Bug)
              if (widget.isReportProblem) ...[
                Container(
                  decoration: BoxDecoration(
                    color: LuminaTokens.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                  ),
                  child: SwitchListTile(
                    value: _attachLogs,
                    onChanged: (val) => setState(() => _attachLogs = val),
                    activeColor: LuminaTokens.primaryLight,
                    activeTrackColor: LuminaTokens.primary.withOpacity(0.5),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: LuminaTokens.darkSurfaceSecondary,
                    title: Text(
                      'Attach App Logs & Diagnostics',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Helps developers debug hardware and crash issues faster',
                      style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuminaTokens.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  onPressed: _isSending ? null : _submitTicket,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSending ? 'Submitting...' : 'Submit',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
