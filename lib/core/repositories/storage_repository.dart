import 'dart:io';
import 'dart:typed_data';
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

  /// Web-safe variant of [uploadAvatar]: uploads raw [bytes] (with the given
  /// file [ext], e.g. `.png`) to the `avatars` bucket, updates
  /// `profiles.avatar_url`, and returns the public URL. Same contract as
  /// [uploadAvatar]; used on Flutter web where `File`/path access is unavailable.
  Future<String> uploadAvatarBytes(
    Uint8List bytes,
    String userId,
    String ext,
  ) async {
    try {
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = '$userId/$fileName';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(storagePath);

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

  /// Returns a short-lived signed URL for an evidence object in the PRIVATE
  /// `guard_evidence` bucket. Stored values may be public URLs (which return
  /// 403 on a private bucket) or bare object paths — this derives the object
  /// key and signs it. Returns null (never throws) on empty input or any error.
  Future<String?> signedEvidenceUrl(String stored) async {
    if (stored.isEmpty) return null;
    try {
      String key;
      const marker = '/guard_evidence/';
      final markerIndex = stored.lastIndexOf(marker);
      if (markerIndex != -1) {
        // Everything after the last `/guard_evidence/`, minus any `?query`.
        key = stored.substring(markerIndex + marker.length);
        final queryIndex = key.indexOf('?');
        if (queryIndex != -1) key = key.substring(0, queryIndex);
      } else {
        // Already an object path.
        key = stored;
      }
      final url = await _supabase.storage
          .from('guard_evidence')
          .createSignedUrl(key, 3600);
      return url;
    } catch (e) {
      print('Error signing evidence url: $e');
      return null;
    }
  }

  /// Uploads a resident's personal document (PDF/image/etc.) to the private
  /// `resident_documents` bucket under the owner's user-id folder, and returns
  /// the stored OBJECT PATH (not a public URL — the bucket is private, so we
  /// sign on read via [signedResidentDocUrl]).
  Future<String> uploadResidentDocument(File file, String userId) async {
    try {
      final ext = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final objectPath = '$userId/$fileName';
      await _supabase.storage
          .from('resident_documents')
          .upload(
            objectPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return objectPath;
    } catch (e) {
      print('Error uploading document: $e');
      throw Exception('Failed to upload document');
    }
  }

  /// Web-safe variant of [uploadResidentDocument]: uploads raw [bytes] (with the
  /// given file [ext], e.g. `.pdf`) to the private `resident_documents` bucket
  /// under the owner's user-id folder, and returns the stored OBJECT PATH. Same
  /// contract as [uploadResidentDocument]; used on Flutter web where
  /// `File`/path access is unavailable.
  Future<String> uploadResidentDocumentBytes(
    Uint8List bytes,
    String userId,
    String ext,
  ) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final objectPath = '$userId/$fileName';
      await _supabase.storage
          .from('resident_documents')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return objectPath;
    } catch (e) {
      print('Error uploading document: $e');
      throw Exception('Failed to upload document');
    }
  }

  /// Uploads a community document (rules/regulations PDF, etc.) to the PUBLIC
  /// `documents` bucket under path `<timestamp>-<fileName>`, and returns the
  /// PUBLIC url. Used by the admin E-Document panel so resident downloads work.
  // NOTE: community files (admin documents + announcement banner images) are
  // stored in the PUBLIC `avatars` bucket under a `community/` folder. The
  // `avatars` bucket + its `avatars_write` policy (INSERT TO authenticated)
  // already exist and are proven to work, so uploads succeed with NO extra SQL.
  Future<String> uploadCommunityDocument(File file, String fileName) async {
    try {
      final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final objectPath =
          'community/${DateTime.now().millisecondsSinceEpoch}-$safe';
      await _supabase.storage
          .from('avatars')
          .upload(
            objectPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _supabase.storage.from('avatars').getPublicUrl(objectPath);
    } catch (e) {
      print('Error uploading community document: $e');
      // Surface the real reason (RLS / missing bucket) so it can be fixed.
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Web-safe variant of [uploadCommunityDocument]: uploads raw [bytes] (with
  /// the given file [ext], e.g. `.pdf`) to the PUBLIC `documents` bucket under
  /// path `<timestamp>-<fileName>`, and returns the PUBLIC url. Same contract as
  /// [uploadCommunityDocument]; used on Flutter web where `File`/path access is
  /// unavailable.
  Future<String> uploadCommunityDocumentBytes(
    Uint8List bytes,
    String fileName,
    String ext,
  ) async {
    try {
      final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final objectPath =
          'community/${DateTime.now().millisecondsSinceEpoch}-$safe';
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return _supabase.storage.from('avatars').getPublicUrl(objectPath);
    } catch (e) {
      print('Error uploading community document: $e');
      // Surface the real reason (RLS / missing bucket) so it can be fixed.
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Short-lived signed URL for a stored resident-document object path (or a
  /// stored public-style URL). Returns null on any failure (never throws).
  Future<String?> signedResidentDocUrl(String stored) async {
    if (stored.isEmpty) return null;
    try {
      var key = stored;
      const marker = '/resident_documents/';
      final idx = stored.lastIndexOf(marker);
      if (idx != -1) key = stored.substring(idx + marker.length);
      final q = key.indexOf('?');
      if (q != -1) key = key.substring(0, q);
      return await _supabase.storage
          .from('resident_documents')
          .createSignedUrl(key, 3600);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort removal of a resident-document object from storage (called
  /// when a resident deletes a document). Never throws.
  Future<void> deleteResidentDocumentFile(String stored) async {
    if (stored.isEmpty) return;
    try {
      var key = stored;
      const marker = '/resident_documents/';
      final idx = stored.lastIndexOf(marker);
      if (idx != -1) key = stored.substring(idx + marker.length);
      final q = key.indexOf('?');
      if (q != -1) key = key.substring(0, q);
      await _supabase.storage.from('resident_documents').remove([key]);
    } catch (_) {
      /* ignore — the DB row is the source of truth; a stray file is harmless */
    }
  }
}
