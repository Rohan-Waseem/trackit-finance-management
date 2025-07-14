import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class UploadReceiptsScreen extends StatefulWidget {
  const UploadReceiptsScreen({super.key});

  @override
  State<UploadReceiptsScreen> createState() => _UploadReceiptsScreenState();
}

class _UploadReceiptsScreenState extends State<UploadReceiptsScreen> {
  final picker = ImagePicker();
  File? _image;
  final _captionController = TextEditingController();
  bool _uploading = false;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF1F1F2E),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) setState(() => _image = File(picked.path));
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.white),
              title: const Text('Pick from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) setState(() => _image = File(picked.path));
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _uploadReceipt() async {
    if (_image == null || _captionController.text.trim().isEmpty) return;
    setState(() => _uploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('receipts/$uid/$fileName.jpg');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).collection('receipts').add({
        'imageUrl': imageUrl,
        'caption': _captionController.text.trim(),
        'timestamp': Timestamp.now(),
      });

      setState(() {
        _image = null;
        _captionController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Receipt uploaded!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Upload failed: $e")),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _deleteReceipt(String docId, String imageUrl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('receipts').doc(docId).delete();
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to delete: $e")),
      );
    }
  }

  void _showReceiptDialog(BuildContext context, String imageUrl, String caption) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1F1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.greenAccent)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Upload Receipts", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5D3FD3), Color(0xFF8E44AD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("New Receipt",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: _image == null
                        ? const Center(child: Icon(Icons.receipt_long, size: 60, color: Colors.white38))
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Caption...",
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Text("Pick", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _uploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton.icon(
                        onPressed: _uploadReceipt,
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: const Text("Upload", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text("Your Receipts",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('receipts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => _showReceiptDialog(context, data['imageUrl'], data['caption']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F2E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['caption'],
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                  Text(
                                    (data['timestamp'] as Timestamp).toDate().toString(),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteReceipt(docs[index].id, data['imageUrl']),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
