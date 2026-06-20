import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository(Supabase.instance.client);
});

class StorageRepository {
  final SupabaseClient _supabase;

  StorageRepository(this._supabase);

  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      final fileExtension = path.extension(imageFile.path);
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final storagePath = '$userId/$fileName';

      // Upload to 'avatars' bucket
      await _supabase.storage
          .from('avatars')
          .upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);

      // Update profile
      await _supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      throw Exception('Failed to upload avatar image');
    }
  }

  Future<String> uploadGuardEvidence(File imageFile, String visitorId) async {
    try {
      final fileExtension = path.extension(imageFile.path);
      final fileName =
          '$visitorId-${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Upload to 'guard_evidence' bucket
      await _supabase.storage
          .from('guard_evidence')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _supabase.storage
          .from('guard_evidence')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading evidence: $e');
      throw Exception('Failed to upload evidence image');
    }
  }
}
