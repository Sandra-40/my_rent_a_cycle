import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'damage_report_screen.dart';
import 'ride_verification_screen.dart';

class RideScreen extends StatefulWidget {
  final String bookingId;
  final String cycleId;
  final String cycleName;

  const RideScreen({
    super.key,
    required this.bookingId,
    required this.cycleId,
    required this.cycleName,
  });

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  static const Color primary = Color(0xFF23717B);
  static const Color darkTeal = Color(0xFFF1F8F8);
  static const Color cyan = Color(0xFF12B2C1);
  static const Color background = Color(0xFF263B40);
  static const Color softTeal = Color(0xFF3A555B);
  static const Color borderColor = Color(0xFF456168);
  static const Color surface = Color(0xFF314B51);
  static const Color mutedText = Color(0xFFB5C9CC);

  Timer? timer;
  Duration elapsed = Duration.zero;
  DateTime? rideStartTime;

  bool isLoading = true;
  bool isEndingRide = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRideDetails();
  }

  Future<void> loadRideDetails() async {
    try {
      final booking = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!booking.exists) {
        throw Exception('Booking not found.');
      }

      final data = booking.data()!;
      final startedAt = data['rideStartedAt'];

      if (startedAt is! Timestamp) {
        throw Exception('Ride start time is not available.');
      }

      rideStartTime = startedAt.toDate();

      updateElapsedTime();

      timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => updateElapsedTime(),
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void updateElapsedTime() {
    if (rideStartTime == null || !mounted) return;

    setState(() {
      elapsed = DateTime.now().difference(rideStartTime!);

      if (elapsed.isNegative) {
        elapsed = Duration.zero;
      }
    });
  }

  String twoDigits(int value) => value.toString().padLeft(2, '0');

  String get formattedTime {
    final hours = twoDigits(elapsed.inHours);
    final minutes = twoDigits(elapsed.inMinutes.remainder(60));
    final seconds = twoDigits(elapsed.inSeconds.remainder(60));

    return '$hours:$minutes:$seconds';
  }

  Future<void> endRide() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'End Your Ride?',
          style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You will need to complete the parking and ride verification process.',
          style: TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Riding', style: TextStyle(color: cyan)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('End Ride'),
          ),
        ],
      ),
    );

    if (shouldEnd != true || !mounted) return;

    setState(() => isEndingRide = true);

    timer?.cancel();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideVerificationScreen(
          bookingId: widget.bookingId,
          cycleId: widget.cycleId,
          cycleName: widget.cycleName,
        ),
      ),
    );

    if (mounted) {
      setState(() => isEndingRide = false);
    }
  }

  void reportDamage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DamageReportScreen(
          bookingId: widget.bookingId,
          cycleId: widget.cycleId,
          cycleName: widget.cycleName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Active Ride',
          style: TextStyle(
            color: darkTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: surface,
        foregroundColor: darkTeal,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: cyan))
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: darkTeal, fontSize: 15),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    Container(
                      height: 88,
                      width: 88,
                      decoration: BoxDecoration(
                        color: softTeal,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.pedal_bike_rounded,
                        color: cyan,
                        size: 52,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Enjoy Your Ride!',
                      style: TextStyle(
                        color: darkTeal,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Your cycle is currently in use.',
                      style: TextStyle(color: mutedText, fontSize: 14),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primary, surface, Color(0xFF3A555B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'RIDE DURATION',
                            style: TextStyle(
                              color: Colors.white70,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),

                          const SizedBox(height: 14),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: cyan, size: 9),
                                SizedBox(width: 7),
                                Text(
                                  'RIDE IN PROGRESS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ride Details',
                            style: TextStyle(
                              color: darkTeal,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _detailRow(
                            Icons.pedal_bike_outlined,
                            'Cycle',
                            widget.cycleName,
                          ),

                          const SizedBox(height: 17),

                          _detailRow(
                            Icons.confirmation_number_outlined,
                            'Booking ID',
                            widget.bookingId,
                          ),

                          const SizedBox(height: 17),

                          _detailRow(
                            Icons.access_time_rounded,
                            'Started At',
                            rideStartTime == null
                                ? '—'
                                : '${twoDigits(rideStartTime!.hour)}:'
                                      '${twoDigits(rideStartTime!.minute)}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: softTeal,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: cyan, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'When you finish riding, park the cycle in the designated area and complete the verification process.',
                              style: TextStyle(
                                color: darkTeal,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: isEndingRide ? null : endRide,
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text(
                          'End Ride',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primary.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: isEndingRide ? null : reportDamage,
                        icon: const Icon(Icons.report_problem_outlined),
                        label: const Text(
                          'Report Damage',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cyan,
                          side: const BorderSide(color: cyan, width: 1.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: softTeal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cyan, size: 19),
        ),
        const SizedBox(width: 11),
        Text(label, style: const TextStyle(color: mutedText, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: darkTeal,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
