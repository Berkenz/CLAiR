/// Shared mock chat history data referenced by History screen and Drawer.
class ChatEntry {
  final String title, date, preview;
  bool saved;
  ChatEntry({required this.title, required this.date, required this.preview, this.saved = false});
}

final List<ChatEntry> sharedChatHistory = [
  ChatEntry(title: 'Land Dispute Assistance', date: 'March 6, 2026',
      preview: 'Could you provide more details about the specific nature of the dispute...', saved: true),
  ChatEntry(title: 'Vehicular Accident Settlement', date: 'January 6, 2026',
      preview: 'The insurance company has offered a settlement of ₱80,000. Based on...'),
  ChatEntry(title: 'Tenant Rights Inquiry', date: 'December 12, 2025',
      preview: 'Under Philippine law, tenants have certain rights regarding security deposits...', saved: true),
];
