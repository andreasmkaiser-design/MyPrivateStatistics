import 'package:private_statistics/features/categories/domain/models/field_type.dart';
import 'package:private_statistics/features/categories/domain/models/time_model.dart';
import 'package:private_statistics/features/onboarding/domain/seed_spec.dart';

/// Pre-built category trees seeded on first launch when the user chooses
/// "Start with example categories".
const kDefaultSeedSpecs = [_kSleep, _kSport];

const _kSleep = SeedSpec(
  uid: 'seed-sleep',
  name: 'Sleep',
  timeModel: TimeModel.dayPreciseRange,
  fields: [
    FieldSpec(uid: 'seed-sleep-duration', name: 'Duration', unit: 'h'),
    FieldSpec(
      uid: 'seed-sleep-quality',
      name: 'Quality',
      type: FieldType.integer,
    ),
  ],
);

const _kSport = SeedSpec(
  uid: 'seed-sport',
  name: 'Sport',
  timeModel: TimeModel.datetimePreciseRange,
  fields: [
    FieldSpec(uid: 'seed-sport-duration', name: 'Duration', unit: 'min'),
    FieldSpec(uid: 'seed-sport-distance', name: 'Distance', unit: 'km'),
  ],
  children: [
    SeedSpec(
      uid: 'seed-sport-running',
      name: 'Running',
      parentUid: 'seed-sport',
      timeModel: TimeModel.datetimePreciseRange,
      fields: [
        FieldSpec(uid: 'seed-sport-running-pace', name: 'Pace', unit: 'min/km'),
      ],
    ),
    SeedSpec(
      uid: 'seed-sport-swimming',
      name: 'Swimming',
      parentUid: 'seed-sport',
      timeModel: TimeModel.datetimePreciseRange,
    ),
  ],
);
