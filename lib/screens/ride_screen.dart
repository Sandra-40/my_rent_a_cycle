import 'dart:async';

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
  final Color green = const Color(0xFF1B8A5A);

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
        title: const Text('End Your Ride?'),
        content: const Text(
          'You will need to complete the parking and ride verification process.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Riding'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
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
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'Active Ride',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Text(errorMessage!, textAlign: TextAlign.center),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const SizedBox(height: 15),

                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F4E9),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.pedal_bike_rounded,
                        color: green,
                        size: 52,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Enjoy Your Ride!',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Your cycle is currently in use.',
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 30),

                    // Ride timer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(22),
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
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.lightGreenAccent,
                                  size: 9,
                                ),
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

                    // Cycle details
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFFE5EBE6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ride Details',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 18),

                          _detailRow(
                            Icons.pedal_bike_outlined,
                            'Cycle',
                            widget.cycleName,
                          ),

                          const SizedBox(height: 15),

                          _detailRow(
                            Icons.confirmation_number_outlined,
                            'Booking ID',
                            widget.bookingId,
                          ),

                          const SizedBox(height: 15),

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

                    const SizedBox(height: 25),

                    // Information card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'When you finish riding, park the cycle in the designated area and complete the verification process.',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // End Ride button
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
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Report Damage button
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
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
        Icon(icon, color: green, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
