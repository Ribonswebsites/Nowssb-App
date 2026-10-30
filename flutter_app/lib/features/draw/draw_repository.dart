/// Lucky draw repository. The server owns odds, entry, the draw itself,
/// the winners list and review moderation.
///
/// Server contract (EconomyApi actions, POST https://nowssb.com/api/economy/<action>,
/// Firebase ID token in Authorization):
///   drawStatus   {}                          -> DrawStatus JSON
///   drawEnter    {drawId}                    -> DrawStatus JSON (entered: true)
///                free: no coins, no purchase; one entry per user per draw.
///   drawWinners  {cursor?, limit?}           -> {winners:[...], nextCursor}
///   drawReview   {claimId, text, stars?}     -> {ok:true, status:'pending'}
///                only the winner of claimId may post; held for moderation.
library;

import '../economy/economy_api.dart';
import 'draw_models.dart';

abstract class DrawRepository {
  Future<DrawStatus> status();
  Future<DrawStatus> enter(String drawId);
  Future<WinnersPage> winners({String? cursor, int limit = 20});
  Future<void> submitReview({required String claimId, required String text, int? stars});
}

class EconomyDrawRepository implements DrawRepository {
  const EconomyDrawRepository();

  @override
  Future<DrawStatus> status() async => DrawStatus.fromJson(await EconomyApi.call('drawStatus'));

  @override
  Future<DrawStatus> enter(String drawId) async =>
      DrawStatus.fromJson(await EconomyApi.call('drawEnter', {'drawId': drawId}));

  @override
  Future<WinnersPage> winners({String? cursor, int limit = 20}) async => WinnersPage.fromJson(
    await EconomyApi.call('drawWinners', {if (cursor != null) 'cursor': cursor, 'limit': limit}),
  );

  @override
  Future<void> submitReview({required String claimId, required String text, int? stars}) async {
    await EconomyApi.call('drawReview', {'claimId': claimId, 'text': text, if (stars != null) 'stars': stars});
  }
}
