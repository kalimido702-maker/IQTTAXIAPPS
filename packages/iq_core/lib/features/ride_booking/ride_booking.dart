// Ride Booking Feature — barrel export

// ── Models ──
export 'data/models/active_trip_model.dart';
export 'data/models/cancel_reason_model.dart';
export 'data/models/incoming_request_model.dart';
export 'data/models/invoice_model.dart';
export 'data/models/ride_request_response_model.dart';
export 'data/models/vehicle_type_model.dart';

// ── Data Sources ──
export 'data/datasources/booking_remote_data_source.dart';
export 'data/datasources/trip_stream_data_source.dart';

// ── Repository ──
export 'domain/repositories/booking_repository.dart';

// ── BLoC: Passenger ──
export 'presentation/bloc/passenger/passenger_trip_bloc.dart';
export 'presentation/bloc/passenger/passenger_trip_event.dart';
export 'presentation/bloc/passenger/passenger_trip_state.dart';

// ── BLoC: Driver ──
export 'presentation/bloc/driver/driver_trip_bloc.dart';
export 'presentation/bloc/driver/driver_trip_event.dart';
export 'presentation/bloc/driver/driver_trip_state.dart';

// ── Shared Widgets ──
export 'presentation/widgets/cancel_reasons_sheet.dart';
export 'presentation/widgets/driver_info_card.dart';
export 'presentation/widgets/searching_driver_animation.dart';
export 'presentation/widgets/swipe_to_accept_button.dart';
export 'presentation/widgets/trip_action_buttons.dart';
export 'presentation/widgets/trip_address_row.dart';
export 'presentation/widgets/trip_fare_breakdown.dart';
export 'presentation/widgets/trip_info_row.dart';
export 'presentation/widgets/trip_rating_widget.dart';
export 'presentation/widgets/vehicle_type_card.dart';
export 'presentation/widgets/waiting_timer_banner.dart';

// ── Passenger Pages ──
export 'presentation/pages/passenger/search_destination_page.dart';
export 'presentation/pages/passenger/ride_selection_page.dart';
export 'presentation/pages/passenger/passenger_active_trip_page.dart';
export 'presentation/pages/passenger/trip_invoice_page.dart';
export 'presentation/pages/passenger/trip_rating_page.dart';

// ── Driver Pages ──
export 'presentation/pages/driver/incoming_request_overlay.dart';
export 'presentation/pages/driver/driver_active_trip_page.dart';
export 'presentation/pages/driver/shipment_proof_page.dart';
export 'presentation/pages/driver/customer_signature_page.dart';
