import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://kghiryjutwjgfdtbjtuq.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnaGlyeWp1dHdqZ2ZkdGJqdHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNTczMjUsImV4cCI6MjA5NjYzMzMyNX0.fMxKxqBtv29cb3Y-3LULiavgW3SYxsMpuB7VNxV31ME';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  try {
    final response = await client.from('visitors').select('status').limit(10);
    print('Existing statuses:');
    print(response);
  } catch (e) {
    print('Error: $e');
  }
}
