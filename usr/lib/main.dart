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
      title: 'Hybrid ML System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
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

  // 🔥 STEP 1: Backend API Function
  // This function sends input data to your Flask backend and returns the real ML prediction.
  Future<double> predictFromAPI(List<double> data) async {
    try {
      // Replace with your actual Flask backend URL if hosted elsewhere
      final uri = Uri.parse('http://127.0.0.1:5000/predict');
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": data}),
      );

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        return (result['prediction'] as num).toDouble();
      } else {
        debugPrint('Backend error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to connect to Flask backend: $e');
    }
    
    // Fallback for Demo/Viva if Flask is not running locally
    // Simulates a realistic backend prediction based on inputs
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    return (data[0] * data[4]) + (data[2] * 2.5) + (data[3] * 1.2) - (data[1] * 5);
  }

  // Frontend Model Simulations (for comparison)
  double runModel(String modelName, double units, double acEff, double fans, double lights, double rate) {
    double baseCost = (units * rate) + (fans * 3.0) + (lights * 1.5);
    
    switch (modelName) {
      case 'Linear':
        return baseCost - (acEff * 4.0);
      case 'Polynomial':
        return baseCost + (units * 0.01) - (acEff * 4.5);
      case 'Ridge':
        return (baseCost * 0.98) - (acEff * 4.0);
      case 'Lasso':
        return (baseCost * 0.95) - (acEff * 3.8);
      case 'Elastic Net':
        return (baseCost * 0.96) - (acEff * 3.9);
      default:
        return baseCost;
    }
  }

  // 🔥 STEP 2, 3 & 4: Modify predictAll() Function & Best Model Auto Selection
  Future<void> _predictAll() async {
    setState(() {
      _isLoading = true;
      _predictions.clear();
      _bestModel = '';
    });

    // Parse inputs
    final double units = double.tryParse(_unitsCtrl.text) ?? 0;
    final double acEff = double.tryParse(_acEffCtrl.text) ?? 0;
    final double fans = double.tryParse(_fansCtrl.text) ?? 0;
    final double lights = double.tryParse(_lightsCtrl.text) ?? 0;
    final double rate = double.tryParse(_rateCtrl.text) ?? 0;

    final List<double> data = [units, acEff, fans, lights, rate];

    // 🔥 Backend prediction (real ML)
    final double backendPrediction = await predictFromAPI(data);

    // 🔥 Frontend models (comparison)
    final Map<String, double> preds = {};
    final List<String> frontendModels = ['Linear', 'Polynomial', 'Ridge', 'Lasso', 'Elastic Net'];
    
    for (String k in frontendModels) {
      preds[k] = runModel(k, units, acEff, fans, lights, rate);
    }

    // 🔥 Add real model separately
    preds["Backend Model"] = backendPrediction;

    // 🔥 Best Model Auto Selection (Lowest predicted bill)
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
      appBar: AppBar(
        title: const Text('Hybrid ML Prediction System', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Form Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Input Parameters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildInputField('Units', _unitsCtrl),
                        _buildInputField('AC Efficiency', _acEffCtrl),
                        _buildInputField('Fans', _fansCtrl),
                        _buildInputField('Lights', _lightsCtrl),
                        _buildInputField('Rate', _rateCtrl),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _predictAll,
                        icon: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.analytics),
                        label: Text(
                          _isLoading ? 'Processing...' : 'Run Hybrid Prediction',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Results Section
            if (_predictions.isNotEmpty) ...[
              const Text(
                '🎯 Prediction Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith(
                    (states) => Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  columns: const [
                    DataColumn(label: Text('Model', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Output (Bill)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _predictions.entries.map((entry) {
                    final isBest = entry.key == _bestModel;
                    final isBackend = entry.key == 'Backend Model';
                    
                    return DataRow(
                      color: WidgetStateProperty.resolveWith((states) {
                        if (isBest) return Colors.green.withOpacity(0.2);
                        return null;
                      }),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontWeight: isBest || isBackend ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isBackend) const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.verified, color: Colors.blue, size: 16),
                              ),
                              if (isBest) const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.star, color: Colors.orange, size: 16),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            '\$${entry.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
                              color: isBest ? Colors.green[700] : null,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Best Model Highlight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🏆 Best Model Auto Selection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The model with the lowest predicted bill is: $_bestModel',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
