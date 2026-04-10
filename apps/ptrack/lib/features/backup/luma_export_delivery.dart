import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';

import 'luma_export_delivery_io.dart'
    if (dart.library.html) 'luma_export_delivery_web.dart' as impl;

Future<void> deliverLumaExport(BuildContext context, ExportResult result) =>
    impl.deliverLumaExport(context, result);
