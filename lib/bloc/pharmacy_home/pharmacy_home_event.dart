abstract class PharmacyHomeEvent {
  const PharmacyHomeEvent();
}

class LoadPharmacyHome extends PharmacyHomeEvent {
  const LoadPharmacyHome(this.pharmacyId);

  final String pharmacyId;
}

class PharmacyHomeRefreshed extends PharmacyHomeEvent {
  const PharmacyHomeRefreshed(this.pharmacyId);

  final String pharmacyId;
}
