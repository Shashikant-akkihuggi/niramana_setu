import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Plot3DConceptScreen extends StatefulWidget {
  final double plotLength;
  final double plotWidth;
  final int floors;

  const Plot3DConceptScreen({
    super.key,
    required this.plotLength,
    required this.plotWidth,
    required this.floors,
  });

  @override
  State<Plot3DConceptScreen> createState() => _Plot3DConceptScreenState();
}

class _Plot3DConceptScreenState extends State<Plot3DConceptScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final double length = widget.plotLength;
    final double width = widget.plotWidth;
    final int floors = widget.floors;
    final double height = floors * 3.0; // 3m per floor

    // Generate HTML content with embedded Three.js
    final String htmlContent =
        '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <style>
          body { margin: 0; overflow: hidden; background-color: #eef2f5; }
          canvas { display: block; outline: none; }
          #info {
            position: absolute;
            top: 10px;
            width: 100%;
            text-align: center;
            font-family: 'Segoe UI', sans-serif;
            color: #555;
            pointer-events: none;
            font-size: 13px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 1px;
          }
        </style>
      </head>
      <body>
        <div id="info">Initializing 3D Concept...</div>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
        <script>
          // Parameters from Flutter
          const plotW = $width;
          const plotL = $length;
          const buildingH = $height;
          const floors = $floors;
          const floorHeight = 3.0;

          let camera, scene, renderer, controls;

          init();
          animate();

          function init() {
            document.getElementById('info').style.display = 'none';

            // 1. Scene & Environment
            scene = new THREE.Scene();
            scene.background = new THREE.Color(0xeef2f5); // Soft sky/paper color
            scene.fog = new THREE.Fog(0xeef2f5, 30, 150); // Depth cue

            // 2. Camera (Perspective, FOV 50, Elevated)
            camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.5, 200);
            // Position: elevated corner view
            camera.position.set(plotW * 1.8, buildingH + 20, plotL * 1.8);

            // 3. Renderer (High Quality)
            renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
            renderer.setSize(window.innerWidth, window.innerHeight);
            renderer.shadowMap.enabled = true;
            renderer.shadowMap.type = THREE.PCFSoftShadowMap; // Softer shadows
            renderer.outputEncoding = THREE.sRGBEncoding;
            renderer.toneMapping = THREE.ACESFilmicToneMapping;
            renderer.toneMappingExposure = 1.0;
            document.body.appendChild(renderer.domElement);

            // 4. Controls (Orbit, Smooth Damping)
            controls = new THREE.OrbitControls(camera, renderer.domElement);
            controls.enableDamping = true;
            controls.dampingFactor = 0.08;
            controls.enablePan = true;
            controls.maxPolarAngle = Math.PI / 2 - 0.02; // Strict ground limit
            controls.minDistance = 5;
            controls.maxDistance = 150;
            controls.target.set(0, buildingH / 3, 0); // Focus on building center

            // 5. Lighting (Realistic & Warm)
            // Ambient (Soft fill)
            const ambientLight = new THREE.AmbientLight(0xffffff, 0.65);
            scene.add(ambientLight);

            // Directional (Sun - Warm)
            const sunLight = new THREE.DirectionalLight(0xfff8e7, 1.2);
            sunLight.position.set(40, 80, 50);
            sunLight.castShadow = true;
            // Optimize shadow map
            sunLight.shadow.mapSize.width = 2048;
            sunLight.shadow.mapSize.height = 2048;
            sunLight.shadow.camera.near = 0.5;
            sunLight.shadow.camera.far = 200;
            sunLight.shadow.bias = -0.0005;
            // Shadow volume size
            const d = 50;
            sunLight.shadow.camera.left = -d;
            sunLight.shadow.camera.right = d;
            sunLight.shadow.camera.top = d;
            sunLight.shadow.camera.bottom = -d;
            scene.add(sunLight);
            
            // Hemisphere (Sky vs Ground reflection)
            const hemiLight = new THREE.HemisphereLight(0xffffff, 0x444444, 0.3);
            hemiLight.position.set(0, 20, 0);
            scene.add(hemiLight);

            // 6. Materials
            const materials = {
              ground: new THREE.MeshStandardMaterial({ 
                color: 0xf0f2f5, // Light gray/concrete
                roughness: 0.9,
                metalness: 0.0 
              }),
              plotBase: new THREE.MeshStandardMaterial({ 
                color: 0xe0e0e0, // Light concrete
                roughness: 0.8,
                metalness: 0.1
              }),
              setback: new THREE.MeshBasicMaterial({
                color: 0x4caf50,
                transparent: true,
                opacity: 0.15,
                side: THREE.DoubleSide
              }),
              building: new THREE.MeshStandardMaterial({
                color: 0xffffff,
                roughness: 0.4,
                metalness: 0.05
              }),
              roof: new THREE.MeshStandardMaterial({
                color: 0xf5f5f5,
                roughness: 0.9
              }),
              edges: new THREE.LineBasicMaterial({ color: 0x888888, opacity: 0.5, transparent: true })
            };

            // 7. Geometry Building
            
            // A. Infinite Ground Plane with Grid
            const groundPlane = new THREE.Mesh(new THREE.PlaneGeometry(500, 500), materials.ground);
            groundPlane.rotation.x = -Math.PI / 2;
            groundPlane.position.y = -0.2;
            groundPlane.receiveShadow = true;
            scene.add(groundPlane);

            const grid = new THREE.GridHelper(500, 100, 0xccd6dd, 0xeef2f5);
            grid.position.y = -0.19;
            grid.material.transparent = true;
            grid.material.opacity = 0.4;
            scene.add(grid);

            // B. Plot Base (The Land)
            const plotGeo = new THREE.BoxGeometry(plotW, 0.1, plotL);
            const plotMesh = new THREE.Mesh(plotGeo, materials.plotBase);
            plotMesh.position.y = -0.05;
            plotMesh.receiveShadow = true;
            scene.add(plotMesh);
            
            // Plot Border (Darker outline)
            const plotEdges = new THREE.LineSegments(
              new THREE.EdgesGeometry(plotGeo), 
              new THREE.LineBasicMaterial({ color: 0x333333 })
            );
            plotEdges.position.y = -0.05;
            scene.add(plotEdges);

            // C. Green Setback Zone (Visual overlay on plot)
            // Visualizes the plot area vs building
            const setbackGeo = new THREE.PlaneGeometry(plotW, plotL);
            const setbackMesh = new THREE.Mesh(setbackGeo, materials.setback);
            setbackMesh.rotation.x = -Math.PI / 2;
            setbackMesh.position.y = 0.02; // Slightly above plot
            scene.add(setbackMesh);

            // D. Building Mass (Floors)
            // Building footprint = 80% of plot (centered)
            const bWidth = plotW * 0.8;
            const bLength = plotL * 0.8;
            
            const floorGroup = new THREE.Group();

            for (let i = 0; i < floors; i++) {
              // Individual Floor Box
              const floorBox = new THREE.BoxGeometry(bWidth, floorHeight - 0.1, bLength); // 0.1 gap
              const floorMesh = new THREE.Mesh(floorBox, materials.building);
              
              // Position: y = (i * 3) + (1.5) -> center of box
              floorMesh.position.y = (i * floorHeight) + (floorHeight / 2);
              floorMesh.castShadow = true;
              floorMesh.receiveShadow = true;
              
              // Add subtle edges
              const fEdges = new THREE.LineSegments(
                new THREE.EdgesGeometry(floorBox),
                materials.edges
              );
              floorMesh.add(fEdges);
              
              floorGroup.add(floorMesh);
            }
            
            // Roof / Terrace (Top of last floor)
            // Just to close it off nicely
            
            scene.add(floorGroup);

            // E. Scale Reference (Simple "Human" block?)
            // No, strictly concept only.

            window.addEventListener('resize', onWindowResize);
          }

          function onWindowResize() {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
          }

          function animate() {
            requestAnimationFrame(animate);
            controls.update();
            renderer.render(scene, camera);
          }
        </script>
      </body>
      </html>
    ''';

    // Initialize WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF0F4F8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: \${error.description}');
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          "3D Concept View (Beta)",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF136DEC)),
            ),

          // Safety Label Overlay
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Concept visualization only. Not for construction.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Plot Info Overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Plot: ${widget.plotLength}m x ${widget.plotWidth}m",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Building: ${widget.floors} Floors",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
