import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/delivery_route_model.dart';

abstract class RiderBatchEvent extends Equatable {
  const RiderBatchEvent();

  @override
  List<Object?> get props => [];
}

class CreateNewRoute extends RiderBatchEvent {
  const CreateNewRoute({
    required this.riderId,
    required this.date,
    this.name,
    this.pharmacyId,
    this.pharmacyName,
    this.carryPreviousStops = false,
    this.startLocation,
  });

  final String riderId;
  final DateTime date;
  final String? name;
  final String? pharmacyId;
  final String? pharmacyName;
  final bool carryPreviousStops;
  final LatLng? startLocation;

  @override
  List<Object?> get props => [
        riderId,
        date,
        name,
        pharmacyId,
        pharmacyName,
        carryPreviousStops,
        startLocation,
      ];
}

class LoadExistingRoute extends RiderBatchEvent {
  const LoadExistingRoute(this.routeId);

  final String routeId;

  @override
  List<Object?> get props => [routeId];
}

class InitBatchSession extends RiderBatchEvent {
  const InitBatchSession({
    required this.riderId,
    this.pharmacyId,
    this.pharmacyName,
    this.existingRoute,
  });

  final String riderId;
  final String? pharmacyId;
  final String? pharmacyName;
  final DeliveryRouteModel? existingRoute;

  @override
  List<Object?> get props => [riderId, pharmacyId, pharmacyName, existingRoute];
}

class ResumeActiveRoute extends RiderBatchEvent {
  const ResumeActiveRoute(this.route);

  final DeliveryRouteModel route;

  @override
  List<Object?> get props => [route];
}

class ScanPackageQr extends RiderBatchEvent {
  const ScanPackageQr(this.qrValue);

  final String qrValue;

  @override
  List<Object?> get props => [qrValue];
}

class ConfirmScannedDelivery extends RiderBatchEvent {
  const ConfirmScannedDelivery(this.stop);

  final RouteStopModel stop;

  @override
  List<Object?> get props => [stop];
}

class EditRouteStop extends RiderBatchEvent {
  const EditRouteStop(this.stop);

  final RouteStopModel stop;

  @override
  List<Object?> get props => [stop];
}

class AddStopNote extends RiderBatchEvent {
  const AddStopNote({
    required this.orderId,
    required this.note,
  });

  final String orderId;
  final String note;

  @override
  List<Object?> get props => [orderId, note];
}

class RemoveScannedPackage extends RiderBatchEvent {
  const RemoveScannedPackage(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class ClearScanFeedback extends RiderBatchEvent {
  const ClearScanFeedback();
}

class OptimizeBatchRoute extends RiderBatchEvent {
  const OptimizeBatchRoute({this.origin});

  final LatLng? origin;

  @override
  List<Object?> get props => [origin];
}

class RefineRouteSequence extends RiderBatchEvent {
  const RefineRouteSequence(this.reorderedStops);

  final List<RouteStopModel> reorderedStops;

  @override
  List<Object?> get props => [reorderedStops];
}

class ConfirmOptimizedRoute extends RiderBatchEvent {
  const ConfirmOptimizedRoute();
}

class StartBatchRoute extends RiderBatchEvent {
  const StartBatchRoute();
}

class UpdateRiderBatchPosition extends RiderBatchEvent {
  const UpdateRiderBatchPosition(this.position);

  final LatLng position;

  @override
  List<Object?> get props => [position];
}

class MarkActiveStopDelivered extends RiderBatchEvent {
  const MarkActiveStopDelivered({this.recipientName});

  final String? recipientName;

  @override
  List<Object?> get props => [recipientName];
}

class MarkActiveStopFailed extends RiderBatchEvent {
  const MarkActiveStopFailed({
    required this.reason,
    this.note,
  });

  final String reason;
  final String? note;

  @override
  List<Object?> get props => [reason, note];
}

class UndoLastStopStatus extends RiderBatchEvent {
  const UndoLastStopStatus();
}

class SelectStopManually extends RiderBatchEvent {
  const SelectStopManually(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class SkipActiveStop extends RiderBatchEvent {
  const SkipActiveStop();
}

class CompleteBatchRun extends RiderBatchEvent {
  const CompleteBatchRun();
}
