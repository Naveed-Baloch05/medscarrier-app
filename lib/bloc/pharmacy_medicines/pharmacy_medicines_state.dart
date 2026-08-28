import '../../models/medicine_model.dart';

abstract class PharmacyMedicinesState {
  const PharmacyMedicinesState();
}

class PharmacyMedicinesInitial extends PharmacyMedicinesState {
  const PharmacyMedicinesInitial();
}

class PharmacyMedicinesLoading extends PharmacyMedicinesState {
  const PharmacyMedicinesLoading();
}

class PharmacyMedicinesLoaded extends PharmacyMedicinesState {
  const PharmacyMedicinesLoaded({
    required this.medicines,
  });

  final List<MedicineModel> medicines;
}

class PharmacyMedicinesError extends PharmacyMedicinesState {
  const PharmacyMedicinesError(this.message);

  final String message;
}
