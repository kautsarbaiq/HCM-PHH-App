import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabaseUrl = 'https://kghiryjutwjgfdtbjtuq.supabase.co';
  final supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnaGlyeWp1dHdqZ2ZkdGJqdHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNTczMjUsImV4cCI6MjA5NjYzMzMyNX0.fMxKxqBtv29cb3Y-3LULiavgW3SYxsMpuB7VNxV31ME';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  try {
    print('1. Trying admin@hcm.com first...');
    AuthResponse? authResponse;
    try {
        authResponse = await client.auth.signInWithPassword(
          email: 'admin@hcm.com',
          password: 'password123',
        );
    } catch(e) {
        print('admin@hcm.com failed. Trying test signup...');
        authResponse = await client.auth.signUp(email: 'ai_test_${DateTime.now().millisecondsSinceEpoch}@gmail.com', password: 'password123');
    }
    
    final userId = authResponse.user!.id;
    print('Logged in successfully! User ID: $userId');
    
    print('2. Fetching profile to get house_id...');
    final profileData = await client.from('profiles').select('id, house_id').eq('id', userId).single();
    
    final profileId = profileData['id'] as String;
    String? houseId = profileData['house_id'] as String?;
    
    if (houseId == null) {
      print('Profile has no house assigned. Fetching any available house...');
      final houseData = await client.from('houses').select('id').limit(1).maybeSingle();
      if (houseData != null) {
         houseId = houseData['id'] as String;
      } else {
         print('No houses found in DB! Creating one...');
         final newHouse = await client.from('houses').insert({'house_number': 'TEST-ADMIN-123'}).select('id').single();
         houseId = newHouse['id'] as String;
      }
    }
    
    print('Using Profile ID: $profileId');
    print('Using House ID: $houseId');
    
    print('3. Attempting to create a Visitor...');
    
    final visitorPayload = {
      'visitor_name': 'Test Visitor AI Authenticated',
      'purpose': 'AI Testing',
      'vehicle_plate': 'B 1234 CD',
      'house_id': houseId,
      'qr_token': 'v-test-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'expected',
      'expected_at': DateTime.now().toIso8601String(),
      'created_by': profileId,
      'registration_type': 'pre-registered'
    };
    
    final result = await client.from('visitors').insert(visitorPayload).select().single();
    
    print('SUCCESS! Visitor inserted:');
    print(result);
    
    print('Cleaning up test visitor...');
    await client.from('visitors').delete().eq('id', result['id']);
    print('Cleaned up.');
    
  } catch (e) {
    print('FAILED TO INSERT VISITOR:');
    print(e);
  }
}
