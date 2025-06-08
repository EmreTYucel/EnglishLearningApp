import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:english_learning_app/providers/statistics_provider.dart';
import 'package:english_learning_app/providers/word_provider.dart';
// Sadece web için yazdırma
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';


class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF olarak Yazdır',
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) => _buildStatisticsPdf(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ana Sayfaya Dön',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Consumer2<StatisticsProvider, WordProvider>(
        builder: (context, stats, wordProvider, child) {
          final allWords = wordProvider.words;
          final learnedWords = wordProvider.getLearnedWords();
          final learningWords = wordProvider.getLearningWords();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCardsWithProvider(context, allWords.length, learnedWords.length, learningWords.length, stats.streak),
                const SizedBox(height: 24),
                _buildProgressChartWithProvider(context, learnedWords.length, allWords.length),
                const SizedBox(height: 24),
                _buildStreakCard(context, stats),
                const SizedBox(height: 24),
                _buildCategorySuccessTable(context, wordProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCardsWithProvider(BuildContext context, int total, int learned, int learning, int streak) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          context,
          'Toplam Kelime',
          total.toString(),
          Icons.book,
          Colors.blue,
        ),
        _buildSummaryCard(
          context,
          'Öğrenilen',
          learned.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _buildSummaryCard(
          context,
          'Öğreniliyor',
          learning.toString(),
          Icons.school,
          Colors.orange,
        ),
        _buildSummaryCard(
          context,
          'Seri',
          '$streak gün',
          Icons.local_fire_department,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChartWithProvider(BuildContext context, int learned, int total) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Öğrenme İlerlemesi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 0),
                        FlSpot(1, learned.toDouble()),
                        FlSpot(2, total.toDouble()),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, StatisticsProvider stats) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Çalışma Serisi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '${stats.streak}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'gün',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Son çalışma: ${_formatDate(stats.lastStudyDate)}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCategorySuccessTable(BuildContext context, WordProvider wordProvider) {
    final allWords = wordProvider.words;
    final learnedWords = wordProvider.getLearnedWords();
    // Kategoriye göre gruplama
    final Map<String, List> categoryMap = {};
    for (var word in allWords) {
      final cat = word.category ?? 'Belirtilmemiş';
      categoryMap.putIfAbsent(cat, () => []).add(word);
    }
    // Öğrenilenleri kategoriye göre gruplama
    final Map<String, int> learnedCountMap = {};
    for (var word in learnedWords) {
      final cat = word.category ?? 'Belirtilmemiş';
      learnedCountMap[cat] = (learnedCountMap[cat] ?? 0) + 1;
    }
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konu/Kategori Bazlı Başarı', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Toplam Kelime')),
                  DataColumn(label: Text('Öğrenilen')),
                  DataColumn(label: Text('Başarı (%)')),
                ],
                rows: categoryMap.entries.map((entry) {
                  final cat = entry.key;
                  final total = entry.value.length;
                  final learned = learnedCountMap[cat] ?? 0;
                  final percent = total > 0 ? (learned / total * 100).toStringAsFixed(1) : '0';
                  return DataRow(cells: [
                    DataCell(Text(cat)),
                    DataCell(Text(total.toString())),
                    DataCell(Text(learned.toString())),
                    DataCell(Text(percent)),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildStatisticsPdf(BuildContext context) async {
    final wordProvider = Provider.of<WordProvider>(context, listen: false);
    final allWords = wordProvider.words;
    final learnedWords = wordProvider.getLearnedWords();
    final learningWords = wordProvider.getLearningWords();

    // Kategori tablosu için hazırlık
    final Map<String, List> categoryMap = {};
    for (var word in allWords) {
      final cat = word.category ?? 'Belirtilmemiş';
      categoryMap.putIfAbsent(cat, () => []).add(word);
    }
    final Map<String, int> learnedCountMap = {};
    for (var word in learnedWords) {
      final cat = word.category ?? 'Belirtilmemiş';
      learnedCountMap[cat] = (learnedCountMap[cat] ?? 0) + 1;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, child: pw.Text('İngilizce Kelime Öğrenme - İstatistik Raporu')),
          pw.Paragraph(text: 'Toplam Kelime: ${allWords.length}'),
          pw.Paragraph(text: 'Öğrenilen Kelime: ${learnedWords.length}'),
          pw.Paragraph(text: 'Öğreniliyor: ${learningWords.length}'),
          pw.SizedBox(height: 16),
          pw.Text('Konu/Kategori Bazlı Başarı', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headers: ['Kategori', 'Toplam', 'Öğrenilen', 'Başarı (%)'],
            data: categoryMap.entries.map((entry) {
              final cat = entry.key;
              final total = entry.value.length;
              final learned = learnedCountMap[cat] ?? 0;
              final percent = total > 0 ? (learned / total * 100).toStringAsFixed(1) : '0';
              return [cat, total.toString(), learned.toString(), percent];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }
} 