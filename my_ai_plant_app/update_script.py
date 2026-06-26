file_path = r'D:\Plan\utrasupervip\my_ai_plant_app\lib\features\scan\screens\scan_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import at the top
content = content.replace("import 'diagnosis_report_screen.dart';", "import 'diagnosis_report_screen.dart';\nimport 'camera_preview_widget.dart';")

# Replace the Scaffold body when selectedImage == null
start_marker = '    return Scaffold('
end_marker = '              // 1. Khung chon anh hoac Preview anh'

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx != -1 and end_idx != -1:
    new_scaffold = '''    if (scanProvider.selectedImage == null) {
      return CameraPreviewWidget(
        scanProvider: scanProvider,
        onHelpTap: () => setState(() => _showInstruction = true),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2FCEF),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        title: const Text('QUET BENH LA CAY AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              setState(() {
                _showInstruction = true;
              });
            },
            tooltip: 'Xem hướng dẫn',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => scanProvider.reset(),
            tooltip: 'Reset',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
'''
    new_content = content[:start_idx] + new_scaffold + content[end_idx:]
    
    # We also need to remove the whole GestureDetector block for 'Khung chon anh hoac Preview anh' when selectedImage is null because we already handled null.
    # We will just replace it with the Image view
    
    # Let's find the GestureDetector block
    gd_start = new_content.find('              // 1. Khung chon anh hoac Preview anh')
    gd_end = new_content.find('              const SizedBox(height: 20);', gd_start)
    if gd_end == -1: gd_end = new_content.find('              const SizedBox(height: 20),', gd_start)
    
    if gd_start != -1 and gd_end != -1:
        new_image_block = '''              // 1. Khung Preview anh
              Container(
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    scanProvider.webImageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
'''
        new_content = new_content[:gd_start] + new_image_block + new_content[gd_end:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Updated scan screen successfully')
else:
    print('Markers not found')
