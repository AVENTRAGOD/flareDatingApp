import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flare_dating_app/services/database_service.dart';

void main() {
  test('Debug getUserStats', () async {
    // We need to initialize Supabase
    await Supabase.initialize(
      url: 'https://yoleyzkonnuxllvsqohi.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvbGV5emtvbm51eGxsdnNxb2hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTUwMTAsImV4cCI6MjA5MTIzMTAxMH0.U50YJdumRR2vbbHcw06SZYXtxcidq00CHhFmk-8x2qs',
    );

    try {
      final stats = await DatabaseService.instance.getUserStats('nisalsayuranga0710@gmail.com');
      print('SUCCESS! Stats: $stats');
    } catch (e) {
      print('FAILED WITH EXCEPTION: $e');
    }
  });
}
