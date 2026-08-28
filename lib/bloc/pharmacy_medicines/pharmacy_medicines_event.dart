abstract class PharmacyMedicinesEvent {
  const PharmacyMedicinesEvent();
}

class LoadPharmacyMedicines extends PharmacyMedicinesEvent {
  const LoadPharmacyMedicines(this.pharmacyId);

  final String pharmacyId;
}

class PharmacyMedicinesRefreshed extends PharmacyMedicinesEvent {
  const PharmacyMedicinesRefreshed();
}

class PharmacyMedicineAdded extends PharmacyMedicinesEvent {
  const PharmacyMedicineAdded({
    required this.name,
    required this.genericName,
    required this.category,
    required this.stock,
    required this.price,
    required this.prescription,
    required this.lowStockThreshold,
  });

  final String name;
  final String genericName;
  final String category;
  final int stock;
  final double price;
  final bool prescription;
  final int lowStockThreshold;
}

class PharmacyMedicineUpdated extends PharmacyMedicinesEvent {
  const PharmacyMedicineUpdated({
    required this.medicineId,
    required this.name,
    required this.genericName,
    required this.category,
    required this.stock,
    required this.price,
    required this.prescription,
    required this.lowStockThreshold,
  });

  final String medicineId;
  final String name;
  final String genericName;
  final String category;
  final int stock;
  final double price;
  final bool prescription;
  final int lowStockThreshold;
}

class PharmacyMedicineDeleted extends PharmacyMedicinesEvent {
  const PharmacyMedicineDeleted(this.medicineId);

  final String medicineId;
}
