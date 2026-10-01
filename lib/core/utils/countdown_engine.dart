import '../../models/countdown_state.dart';
import 'countdown_utils.dart';

export '../../models/countdown_state.dart';

typedef CountdownTime = CountdownState;

/// Bridge engine providing high-level calculation delegating to [CountdownUtils]
class CountdownEngine {
  CountdownEngine._();

  static CountdownState calculate(DateTime target, [DateTime? from]) {
    return CountdownUtils.calculate(target, now: from);
  }
}
