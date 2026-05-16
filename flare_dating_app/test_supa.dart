import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://yoleyzkonnuxllvsqohi.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvbGV5emtvbm51eGxsdnNxb2hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTUwMTAsImV4cCI6MjA5MTIzMTAxMH0.U50YJdumRR2vbbHcw06SZYXtxcidq00CHhFmk-8x2qs',
  );

  print('=== START DB TEST ===');
  try {
    print('Testing interactions table...');
    final interactions = await supabase.from('interactions').select().limit(1);
    print('Interactions: $interactions');
  } catch (e) {
    print('Interactions Error: $e');
  }

  try {
    print('Testing messages table...');
    final messages = await supabase.from('messages').select().limit(1);
    print('Messages: $messages');
  } catch (e) {
    print('Messages Error: $e');
  }

  try {
    print('Testing chats table...');
    final chats = await supabase.from('chats').select().limit(1);
    print('Chats: $chats');
  } catch (e) {
    print('Chats Error: $e');
  }
}
