import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How does Lumina find photos of me?',
      answer: 'Lumina uses secure, cloud-based facial recognition signatures. When you register your profile selfie, we generate a localized vector signature. Our backend runs this signature against all uploaded group photos inside albums you have joined, filtering matched photos straight to your gallery.',
    ),
    FAQItem(
      question: 'Is my facial biometrics data secure?',
      answer: 'Yes, your privacy is our priority. We generate encryption keys so your face vector signature can only be verified inside groups you explicitly join. We do not store raw images of your profile selfies once signatures are verified, and you can delete your face data completely anytime from Settings -> Privacy & Security.',
    ),
    FAQItem(
      question: 'Can I opt-out of face matching?',
      answer: 'Absolutely. You can toggle off face matching from Settings -> Privacy and Security -> Face Data Management. Once turned off, you will not appear in new face searches inside group albums.',
    ),
    FAQItem(
      question: 'How do sharing codes work?',
      answer: 'Every event album has a unique 6-digit sharing code (e.g. evt123) and a matching QR code. Anyone with the code or QR scan can join as a guest to view shared photos, upload new ones, and run face matching queries.',
    ),
    FAQItem(
      question: 'What happens if my subscription expires?',
      answer: 'If your subscription expires, your account is transitioned to the Free tier. Your storage quota is limited to 1 GB, and watermark-free high-res downloads will be restricted. However, all your existing photos and albums will remain secure.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          'FAQ',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqItems.length,
              itemBuilder: (context, index) {
                final item = _faqItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: LuminaTokens.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          item.question,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Icon(
                          item.isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: LuminaTokens.primaryLight,
                        ),
                        onTap: () {
                          setState(() {
                            item.isExpanded = !item.isExpanded;
                          });
                        },
                      ),
                      if (item.isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            item.answer,
                            style: GoogleFonts.inter(
                              color: LuminaTokens.darkTextMuted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
