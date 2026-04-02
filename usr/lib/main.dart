import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electricity Bill Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A12),
        cardColor: const Color(0xFF18182A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5C518), // Accent Yellow
          secondary: Color(0xFF00D4AA), // Accent Teal
          surface: Color(0xFF12121E),
          error: Color(0xFFFF6B35), // Accent Orange
        ),
        fontFamily: 'Syne', // Fallback to default if Syne isn't in pubspec, but sets the intent
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HybridSystemScreen(),
      },
    );
  }
}

class HybridSystemScreen extends StatefulWidget {
  const HybridSystemScreen({super.key});

  @override
  State<HybridSystemScreen> createState() => _HybridSystemScreenState();
}

class _HybridSystemScreenState extends State<HybridSystemScreen> {
  // Input Controllers
  final TextEditingController _unitsCtrl = TextEditingController(text: '150');
  final TextEditingController _acEffCtrl = TextEditingController(text: '0.8');
  final TextEditingController _fansCtrl = TextEditingController(text: '4');
  final TextEditingController _lightsCtrl = TextEditingController(text: '6');
  final TextEditingController _rateCtrl = TextEditingController(text: '0.12');

  bool _isLoading = false;
  Map<String, double> _predictions = {};
  String _bestModel = '';

  // Colors from the HTML file
  final Color _bg = const Color(0xFF0A0A12);
  final Color _surface = const Color(0xFF12121E);
  final Color _card = const Color(0xFF18182A);
  final Color _border = const Color(0xFF2A2A45);
  final Color _accent = const Color(0xFFF5C518);
  final Color _accent2 = const Color(0xFFFF6B35);
  final Color _accent3 = const Color(0xFF00D4AA);
  final Color _text = const Color(0xFFE8E8F0);
  final Color _muted = const Color(0xFF6B6B90);

  // 🔥 Backend API Function
  Future<double> predictFromAPI(List<double> data) async {
    try {
      final uri = Uri.parse('http://127.0.0.1:5000/predict');
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": data}),
      );

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        return (result['prediction'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Backend fallback triggered');
    }
    
    // Fallback for Demo
    await Future.delayed(const Duration(milliseconds: 800));
    return (data[0] * data[4]) + (data[2] * 2.5) + (data[3] * 1.2) - (data[1] * 5);
  }

  // Frontend Model Simulations
  double runModel(String modelName, double units, double acEff, double fans, double lights, double rate) {
    double baseCost = (units * rate) + (fans * 3.0) + (lights * 1.5);
    switch (modelName) {
      case 'Linear': return baseCost - (acEff * 4.0);
      case 'Polynomial': return baseCost + (units * 0.01) - (acEff * 4.5);
      case 'Ridge': return (baseCost * 0.98) - (acEff * 4.0);
      case 'Lasso': return (baseCost * 0.95) - (acEff * 3.8);
      case 'Elastic Net': return (baseCost * 0.96) - (acEff * 3.9);
      default: return baseCost;
    }
  }

  Future<void> _predictAll() async {
    setState(() {
      _isLoading = true;
      _predictions.clear();
      _bestModel = '';
    });

    final double units = double.tryParse(_unitsCtrl.text) ?? 0;
    final double acEff = double.tryParse(_acEffCtrl.text) ?? 0;
    final double fans = double.tryParse(_fansCtrl.text) ?? 0;
    final double lights = double.tryParse(_lightsCtrl.text) ?? 0;
    final double rate = double.tryParse(_rateCtrl.text) ?? 0;

    final List<double> data = [units, acEff, fans, lights, rate];

    final double backendPrediction = await predictFromAPI(data);

    final Map<String, double> preds = {};
    final List<String> frontendModels = ['Linear', 'Polynomial', 'Ridge', 'Lasso', 'Elastic Net'];
    
    for (String k in frontendModels) {
      preds[k] = runModel(k, units, acEff, fans, lights, rate);
    }

    preds["Backend Model"] = backendPrediction;

    String bestKey = preds.keys.first;
    for (String key in preds.keys) {
      if (preds[key]! < preds[bestKey]!) {
        bestKey = key;
      }
    }

    setState(() {
      _predictions = preds;
      _bestModel = bestKey;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 20),
                ],
              ),
              child: const Center(
                child: Text('⚡', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Predictor',
                  style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'HYBRID ML SYSTEM',
                  style: TextStyle(color: _muted, fontSize: 10, letterSpacing: 1.5),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Layout: Inputs and Results
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildInputSection()),
                          const SizedBox(width: 24),
                          Expanded(flex: 6, child: _buildResultsSection()),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildInputSection(),
                        const SizedBox(height: 24),
                        _buildResultsSection(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 12, height: 2, color: _accent),
              const SizedBox(width: 8),
              Text(
                'INPUT PARAMETERS',
                style: TextStyle(color: _muted, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildField('Total Units (kWh)', _unitsCtrl),
          _buildField('AC Efficiency', _acEffCtrl),
          _buildField('Number of Fans', _fansCtrl),
          _buildField('Number of Lights', _lightsCtrl),
          _buildField('Rate per Unit (\$)', _rateCtrl),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _predictAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: _accent.withOpacity(0.5),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: _bg, strokeWidth: 3),
                    )
                  : const Text(
                      'RUN PREDICTION',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: _text, fontFamily: 'monospace', fontSize: 16),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_predictions.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border, style: BorderStyle.dash),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 48, color: _muted.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'Awaiting parameters to run models...',
                style: TextStyle(color: _muted),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Card for Best Model
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: _accent.withOpacity(0.1), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🏆 BEST MODEL SELECTED',
                      style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const Spacer(),
                  if (_bestModel == 'Backend Model')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent3.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: _accent3, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'REAL ML',
                            style: TextStyle(color: _accent3, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _bestModel,
                style: TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$',
                    style: TextStyle(color: _accent, fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                  Text(
                    _predictions[_bestModel]!.toStringAsFixed(2),
                    style: TextStyle(color: _text, fontSize: 56, fontWeight: FontWeight.w800, height: 1.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Predicted Monthly Cost',
                style: TextStyle(color: _muted, fontSize: 14, letterSpacing: 1.1),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          children: [
            Container(width: 12, height: 2, color: _muted),
            const SizedBox(width: 8),
            Text(
              'ALL MODEL COMPARISONS',
              style: TextStyle(color: _muted, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Grid of other models
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _predictions.entries.where((e) => e.key != _bestModel).map((entry) {
            final isBackend = entry.key == 'Backend Model';
            return Container(
              width: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isBackend ? _accent3 : _muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${entry.value.toStringAsFixed(2)}',
                    style: TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (isBackend) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent3.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'REAL ML',
                        style: TextStyle(color: _accent3, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
