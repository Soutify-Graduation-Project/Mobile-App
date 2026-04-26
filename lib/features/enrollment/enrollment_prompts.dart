/// Visual enrollment: one picture per step. [phrase] is still sent with each
/// clip for the server and file naming; [semanticsLabel] drives screen readers.
class EnrollmentVisualPrompt {
  const EnrollmentVisualPrompt({
    required this.phrase,
    required this.imageAsset,
    required this.semanticsLabel,
  });

  final String phrase;
  final String imageAsset;
  final String semanticsLabel;
}

const List<EnrollmentVisualPrompt> enrollmentVisualPrompts = [
  EnrollmentVisualPrompt(
    phrase: 'قطّة',
    imageAsset: 'assets/cat.jpg',
    semanticsLabel: 'صورة قطة. اضغط الميكروفون وقل كلمة القطّة.',
  ),
  EnrollmentVisualPrompt(
    phrase: 'أسد',
    imageAsset: 'assets/lion.jpg',
    semanticsLabel: 'صورة أسد. اضغط الميكروفون وقل كلمة أسد.',
  ),
  EnrollmentVisualPrompt(
    phrase: 'فيل',
    imageAsset: 'assets/elephant.jpg',
    semanticsLabel: 'صورة فيل. اضغط الميكروفون وقل كلمة فيل.',
  ),
  EnrollmentVisualPrompt(
    phrase: 'فراولة',
    imageAsset: 'assets/strawberry.jpg',
    semanticsLabel: 'صورة فراولة. اضغط الميكروفون وقل كلمة فراولة.',
  ),
  EnrollmentVisualPrompt(
    phrase: 'مانجو',
    imageAsset: 'assets/mango.jpg',
    semanticsLabel: 'صورة مانجو. اضغط الميكروفون وقل كلمة مانجو.',
  ),
  EnrollmentVisualPrompt(
    phrase: 'كلب',
    imageAsset: 'assets/dog.jpg',
    semanticsLabel: 'صورة كلب. اضغط الميكروفون وقل كلمة كلب.',
  ),
];
