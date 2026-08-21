import 'package:flutter/material.dart';

class RiderDeliveryDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const RiderDeliveryDetailsScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<RiderDeliveryDetailsScreen> createState() =>
      _RiderDeliveryDetailsScreenState();
}

class _RiderDeliveryDetailsScreenState
    extends State<RiderDeliveryDetailsScreen> {
  late String deliveryStatus;

  @override
  void initState() {
    super.initState();

    deliveryStatus =
        widget.delivery['status']?.toString() ?? 'Assigned';
  }

  bool get isControlledDrug =>
      widget.delivery['controlledDrug'] == true;

  bool get isColdChain =>
      widget.delivery['coldChain'] == true;

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.black,
          ),
        ),

        title: const Text(
          'Delivery Details',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          children: [
            _buildOrderHeader(delivery),

            const SizedBox(height: 18),

            _buildRouteCard(delivery),

            const SizedBox(height: 18),

            _buildDeliveryInformation(delivery),

            const SizedBox(height: 18),

            if (isControlledDrug || isColdChain)
              _buildSpecialRequirements(),

            if (isControlledDrug || isColdChain)
              const SizedBox(height: 18),

            _buildDeliveryItems(),

            const SizedBox(height: 22),

            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ORDER HEADER
  // ============================================================

  Widget _buildOrderHeader(
      Map<String, dynamic> delivery,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              Icons.local_shipping_outlined,
              color: Colors.grey.shade700,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  delivery['orderId']?.toString() ??
                      'Order',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Delivery Order',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          _statusBadge(deliveryStatus),
        ],
      ),
    );
  }

  // ============================================================
  // ROUTE
  // ============================================================

  Widget _buildRouteCard(
      Map<String, dynamic> delivery,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Route',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          _routeLocation(
            icon: Icons.local_pharmacy_outlined,
            title: 'Pickup from',
            name: delivery['pharmacy']?.toString() ??
                'Pharmacy',
            address: delivery['address']?.toString() ??
                'Pharmacy address',
          ),

          Padding(
            padding: const EdgeInsets.only(
              left: 18,
            ),
            child: Container(
              height: 28,
              width: 1,
              color: Colors.grey.shade300,
            ),
          ),

          _routeLocation(
            icon: Icons.location_on_outlined,
            title: 'Deliver to',
            name: delivery['customer']?.toString() ??
                'Customer',
            address: 'Customer delivery address',
          ),
        ],
      ),
    );
  }

  Widget _routeLocation({
    required IconData icon,
    required String title,
    required String name,
    required String address,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,

          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            size: 19,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DELIVERY INFORMATION
  // ============================================================

  Widget _buildDeliveryInformation(
      Map<String, dynamic> delivery,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _infoItem(
                  icon: Icons.route_outlined,
                  title: 'Distance',
                  value:
                  delivery['distance']?.toString() ??
                      '--',
                ),
              ),

              Expanded(
                child: _infoItem(
                  icon: Icons.access_time_outlined,
                  title: 'ETA',
                  value:
                  delivery['eta']?.toString() ??
                      '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.grey.shade700,
        ),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SPECIAL REQUIREMENTS
  // ============================================================

  Widget _buildSpecialRequirements() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Special Requirements',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 13),

          if (isControlledDrug)
            _requirementTile(
              icon: Icons.warning_amber_rounded,
              title: 'Controlled Drug',
              description:
              'Recipient verification and delivery confirmation are required.',
            ),

          if (isControlledDrug && isColdChain)
            const SizedBox(height: 10),

          if (isColdChain)
            _requirementTile(
              icon: Icons.ac_unit_rounded,
              title: 'Cold Chain',
              description:
              'Keep the medicine within the required temperature conditions during delivery.',
            ),
        ],
      ),
    );
  }

  Widget _requirementTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(13),
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERY ITEMS
  // ============================================================

  Widget _buildDeliveryItems() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Items',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 13),

          _medicineRow(
            'Medicine Item',
            '1 item',
          ),
        ],
      ),
    );
  }

  Widget _medicineRow(
      String name,
      String quantity,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 20,
            color: Colors.grey.shade700,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            quantity,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _buildActionButton() {
    String buttonText;

    if (deliveryStatus == 'Assigned' ||
        deliveryStatus == 'Ready for Pickup') {
      buttonText = 'Go to Pickup';
    } else if (deliveryStatus == 'Picked Up') {
      buttonText = 'Go to Customer';
    } else if (deliveryStatus == 'On the Way') {
      buttonText = 'Continue Delivery';
    } else {
      buttonText = 'Delivery Completed';
    }

    return SizedBox(
      width: double.infinity,
      height: 52,

      child: ElevatedButton(
        onPressed:
        deliveryStatus == 'Delivered'
            ? null
            : _handleDeliveryAction,

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          Colors.grey.shade300,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        child: Text(
          buttonText,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DELIVERY ACTION
  // ============================================================

  void _handleDeliveryAction() {
    if (deliveryStatus == 'Assigned' ||
        deliveryStatus == 'Ready for Pickup') {
      _showPickupMessage();
      return;
    }

    if (deliveryStatus == 'Picked Up') {
      _showCustomerMessage();
      return;
    }

    if (deliveryStatus == 'On the Way') {
      _showCustomerMessage();
      return;
    }
  }

  // ============================================================
  // PICKUP
  // ============================================================

  void _showPickupMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pickup navigation and QR scanner will be connected next.',
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  void _showCustomerMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Customer navigation will be connected next.',
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}