import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class PlantProfileEvent extends Equatable {
  const PlantProfileEvent();

  @override
  List<Object?> get props => [];
}

class PlantProfileLoadRequested extends PlantProfileEvent {
  final String? plantId;

  const PlantProfileLoadRequested({this.plantId});

  @override
  List<Object?> get props => [plantId];
}

class PlantProfileCreateRequested extends PlantProfileEvent {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? description;
  final int? tdsLevel;
  final double? pricePerLiter;
  final String? operatingHours;

  const PlantProfileCreateRequested({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.description,
    this.tdsLevel,
    this.pricePerLiter,
    this.operatingHours,
  });

  @override
  List<Object?> get props => [
        name,
        address,
        latitude,
        longitude,
        phone,
        description,
        tdsLevel,
        pricePerLiter,
        operatingHours,
      ];
}

class PlantProfileUpdateRequested extends PlantProfileEvent {
  final String plantId;
  final Map<String, dynamic> updates;

  const PlantProfileUpdateRequested({
    required this.plantId,
    required this.updates,
  });

  @override
  List<Object?> get props => [plantId, updates];
}

class PlantProfileStatusToggleRequested extends PlantProfileEvent {
  final String plantId;
  final bool isActive;

  const PlantProfileStatusToggleRequested({
    required this.plantId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [plantId, isActive];
}

class PlantProfilePhotoUploadRequested extends PlantProfileEvent {
  final String plantId;
  final File file;

  const PlantProfilePhotoUploadRequested({
    required this.plantId,
    required this.file,
  });

  @override
  List<Object?> get props => [plantId, file];
}

class PlantProfilePhotoDeleteRequested extends PlantProfileEvent {
  final String plantId;
  final int photoIndex;

  const PlantProfilePhotoDeleteRequested({
    required this.plantId,
    required this.photoIndex,
  });

  @override
  List<Object?> get props => [plantId, photoIndex];
}
