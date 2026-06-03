import 'package:flutter/material.dart';

class BannersAdminPage extends StatelessWidget {
  const BannersAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Banners Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B3674),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4318FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 800) crossAxisCount = 3;
                  else if (constraints.maxWidth > 500) crossAxisCount = 2;
                  
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 16 / 9,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FE),
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage('https://via.placeholder.com/600x400/4318FF/FFFFFF?text=Banner+Image'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.edit, color: Color(0xFF4318FF), size: 16), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                    IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 16), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
