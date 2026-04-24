import '../../core/config/env.dart';

/// Full Terms & Privacy text (Pagewalker Final Vision And Legal Prompt.pdf).
/// Public support: [Env.contactEmail] only (no personal admin addresses).
class LegalDocuments {
  LegalDocuments._();

  static String get lastUpdated => 'March ${Env.copyrightYear}';

  static String get termsFullText => '''
TERMS AND CONDITIONS OF USE

Welcome to Pagewalker. By downloading, installing, or using the Pagewalker mobile application, you agree to be bound by these Terms and Conditions. Please read them carefully. If you do not agree to these terms, do not use the app.

1. ABOUT PAGEWALKER
Pagewalker is a book discovery and social discussion platform. It allows users to search for books, view book information, share opinions and reviews, track their personal reading, and connect with other readers.
Pagewalker does not sell, distribute, or host copyrighted book content. All book information displayed (titles, authors, summaries, cover images) is sourced from publicly available APIs including Google Books API and Open Library, and is used for informational and discussion purposes only.
External links to third-party platforms (Amazon, Google Play Books, Project Gutenberg, local libraries) are provided as a convenience. Pagewalker is not responsible for content on external websites.

2. ELIGIBILITY
You must be at least 13 years old to create a Pagewalker account. By creating an account, you confirm that you meet this age requirement.
Users between 13 and 17 years old should have parental permission before using the app.

3. USER ACCOUNTS
3.1 You are responsible for maintaining the confidentiality of your account credentials. Do not share your password with anyone.
3.2 You are responsible for all activity that occurs under your account.
3.3 You must provide accurate information when creating your account.
3.4 One person may only maintain one active account. Creating multiple accounts to circumvent bans or restrictions is prohibited.
3.5 You may delete your account at any time from the Profile Settings screen. Upon deletion, your personal data will be removed within 30 days.

4. USER CONTENT
4.1 Ownership — You retain full ownership of all content you create on Pagewalker, including reviews, comments, ratings, quotes, and profile information.
4.2 Licence to Pagewalker — By posting content on Pagewalker, you grant us a non-exclusive, worldwide, royalty-free licence to display your content to other users within the app. This licence ends when you delete your content or your account.
4.3 Content Standards — You agree that your content will NOT: be offensive, abusive, hateful, or discriminatory; harass, bully, or threaten other users; contain sexually explicit material; promote violence or illegal activities; infringe on the intellectual property of others; contain spam, advertisements, or promotional material; reveal private information about others without consent; contain false or misleading information.
4.4 Spoiler Policy — When posting content that reveals major plot points, you must use the spoiler toggle. Repeatedly posting unmarked spoilers may result in account suspension.
4.5 Moderation — Pagewalker reserves the right to remove any content that violates these terms without notice. We reserve the right to suspend or permanently ban accounts that repeatedly violate our content standards.

5. BOOK INFORMATION AND COPYRIGHT
5.1 Book information displayed on Pagewalker (titles, authors, descriptions, cover images) is sourced from publicly available third-party APIs. This information is used for identification and discussion purposes.
5.2 Pagewalker does not host, store, or distribute copyrighted book text. Users who wish to read books must obtain them through legitimate channels such as libraries, bookstores, or licensed digital platforms.
5.3 External links to Project Gutenberg are provided for books in the public domain only. These links direct users to the external Project Gutenberg website.
5.4 If you believe any content on Pagewalker infringes your copyright, please contact us at ${Env.contactEmail} with details of the infringement.

6. BOOK CLUB ROOMS
6.1 Book Club administrators are responsible for moderating their rooms and ensuring members comply with these terms.
6.2 Pagewalker reserves the right to dissolve any Book Club that is used for purposes that violate these terms.
6.3 Invite codes must not be shared publicly without the consent of the Book Club administrator.

7. PROHIBITED ACTIVITIES
You agree NOT to: use the app for any illegal purpose; attempt to hack, disrupt, or compromise the app; use automated tools, bots, or scrapers on the platform; impersonate another person or entity; collect or harvest other users' personal information; use the app to send unsolicited messages or spam; interfere with other users' enjoyment of the app; attempt to circumvent any security measures.

8. INTELLECTUAL PROPERTY
The Pagewalker name, logo, walking book character, and app design are the intellectual property of Pagewalker and are protected by applicable intellectual property laws. You may not reproduce, distribute, or create derivative works from Pagewalker's branding, design, or character without written permission.

9. DISCLAIMERS
9.1 Pagewalker is provided "as is" without warranties of any kind, express or implied.
9.2 We do not guarantee that the app will be available at all times or free from errors.
9.3 We are not responsible for the accuracy of book information provided by third-party APIs.
9.4 We are not responsible for content posted by users. Reviews and comments reflect the opinions of individual users and not Pagewalker.
9.5 We are not responsible for any loss of data. We recommend users keep personal notes and quotes backed up.

10. LIMITATION OF LIABILITY
To the maximum extent permitted by law, Pagewalker shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the app, including but not limited to loss of data, loss of reading progress, or inability to access the service.

11. CHANGES TO THESE TERMS
We may update these Terms and Conditions from time to time. We will notify users of significant changes through the app. Your continued use of Pagewalker after changes are posted constitutes your acceptance of the updated terms.

12. TERMINATION
Pagewalker reserves the right to suspend or terminate your account at any time if you violate these terms, without prior notice. You may terminate your account at any time from the Profile Settings screen.

13. GOVERNING LAW
These Terms and Conditions are governed by applicable law. Any disputes will be resolved through good faith negotiation before any legal action is taken.

14. CONTACT
For any questions about these Terms and Conditions:
Email: ${Env.contactEmail}
App: Pagewalker
We will respond to all enquiries within 30 days.

© ${Env.copyrightYear} Pagewalker. All rights reserved.
''';

  static String get privacyFullText => '''
PRIVACY POLICY

At Pagewalker, your privacy matters to us deeply. This Privacy Policy explains what information we collect, how we use it, how we protect it, and what rights you have over your data. By using Pagewalker, you agree to the collection and use of information in accordance with this policy.

1. INFORMATION WE COLLECT
1.1 Information You Give Us Directly — When you create an account: email address (required), display name (required), username (required). When you set up your profile (all optional): profile photo, bio, age, location (city/country — not precise GPS), favourite genre, Instagram handle, Facebook name, reading goal, whether your profile is public or private. When you use the app: books you add to your library (TBR, Reading, Read, DNF), star ratings, tier rankings, reviews and comments, quotes and scenes, characters you rank, reading sessions (reading timer), book clubs you create or join, messages you send in book clubs.
1.2 Information We Collect Automatically — App version, device type and operating system, time and date of app use, which features you use. We do NOT collect: precise GPS location, your contacts, your browsing history outside the app, or any information from other apps on your device.

2. HOW WE USE YOUR INFORMATION
We use your information to: create and manage your account; display your profile to other users (if public); power your personal library and reading tracking; generate Reading Wraps and Yearly Wrapped; provide personalised book recommendations using AI (we send reading preferences to OpenAI — no personally identifiable information is shared); enable social features; send push notifications (only with your permission); improve the app; respond to support requests; ensure security.

3. HOW WE SHARE YOUR INFORMATION
We do NOT sell your personal information. Ever. We share data only with: Supabase (database — see supabase.com/privacy); Google Books API (search queries only — no personal information); Open Library / Internet Archive (search queries only); OpenAI (Mood Read — mood input and genres/tropes only, not name or email — see openai.com/privacy); other Pagewalker users according to your public/private settings. Book Club messages are visible to all members of that club.

4. DATA STORAGE AND SECURITY
Your data is stored on Supabase with HTTPS/TLS, encryption at rest, and row-level security. Passwords are never stored in plain text (bcrypt). Profile photos use Supabase Storage with secure access. We retain data while your account is active; deletion within 30 days of account deletion.

5. CAMERA AND PHOTO LIBRARY
Camera: ISBN scanner only. Photo library: profile photo selection only — we never scan your full library.

6. PUSH NOTIFICATIONS
Only with explicit permission. You can disable in app or device settings.

7. CHILDREN'S PRIVACY
Not directed at children under 13. Contact ${Env.contactEmail} if you believe a child under 13 created an account.

8. YOUR RIGHTS AND CHOICES
Access, correct, delete your account from Profile Settings; export data by emailing ${Env.contactEmail} (response within 30 days); control public/private profile; opt out of notifications; withdraw consent by deleting your account.

9. THIRD PARTY LINKS
Links open in your external browser. We are not responsible for external privacy practices.

10. CHANGES TO THIS PRIVACY POLICY
We may update this policy; we will notify you of significant changes with at least 7 days notice where required. Continued use means acceptance.

11. CONTACT US
Email: ${Env.contactEmail} — App: Pagewalker — We respond within 30 days. For urgent data deletion, include "URGENT DATA DELETION" in the subject line (response within 7 days).

© ${Env.copyrightYear} Pagewalker. All rights reserved.
''';

  static String get contactEmail => Env.contactEmail;
}

