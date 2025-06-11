import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  String _resultText = '';
  bool _isLoading = false;

  final List<String> _currencies = [
    'IDR',
    'USD',
    'EUR',
    'JPY',
    'GBP',
    'AUD',
    'SGD',
    'MYR',
  ];

  // GANTI DENGAN API KEY VALID ANDA dari https://www.exchangerate-api.com/
  final String _apiKey = "5ffaba653e70a87a57033da2";

  Future<void> _convert() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah terlebih dahulu.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://v6.exchangerate-api.com/v6/$_apiKey/latest/$_fromCurrency',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] == 'error') {
          throw Exception('Error dari API: ${data['error-type']}');
        }
        final rate = data['conversion_rates'][_toCurrency];
        final amount = double.parse(_amountController.text);
        final convertedAmount = (amount * rate).toStringAsFixed(2);
        setState(
          () => _resultText =
              '$amount $_fromCurrency = $convertedAmount $_toCurrency',
        );
      } else {
        throw Exception(
          'Gagal memuat data kurs (Status Code: ${response.statusCode})',
        );
      }
    } catch (e) {
      setState(() => _resultText = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTimeCard(String zone, String time) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(zone),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alat Konverter")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Konverter Waktu Real-time",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                DateTime utcTime = DateTime.now().toUtc();
                final timeFormat = DateFormat('HH:mm:ss');
                return Column(
                  children: [
                    _buildTimeCard("London (UTC)", timeFormat.format(utcTime)),
                    _buildTimeCard(
                      "WIB (UTC+7)",
                      timeFormat.format(utcTime.add(const Duration(hours: 7))),
                    ),
                    _buildTimeCard(
                      "WITA (UTC+8)",
                      timeFormat.format(utcTime.add(const Duration(hours: 8))),
                    ),
                    _buildTimeCard(
                      "WIT (UTC+9)",
                      timeFormat.format(utcTime.add(const Duration(hours: 9))),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 40, thickness: 1),
            Text(
              "Konverter Mata Uang Dinamis",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildCurrencyDropdown(
                    'Dari',
                    _fromCurrency,
                    (val) => setState(() => _fromCurrency = val!),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.swap_horiz, size: 32),
                ),
                Expanded(
                  child: _buildCurrencyDropdown(
                    'Ke',
                    _toCurrency,
                    (val) => setState(() => _toCurrency = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _convert,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Konversi'),
                  ),
            const SizedBox(height: 24),
            if (_resultText.isNotEmpty)
              Center(
                child: Text(
                  _resultText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(
    String label,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          onChanged: onChanged,
          items: _currencies.map<DropdownMenuItem<String>>((String currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(currency),
            );
          }).toList(),
        ),
      ),
    );
  }
}
