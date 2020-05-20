import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_yyets/ui/load/LoadingStatus.dart';
import 'package:flutter_yyets/utils/toast.dart';

///
/// 数据列表
///
abstract class LoadingPageState<P extends StatefulWidget> extends State<P>
    with AutomaticKeepAliveClientMixin {
  final List items = [];
  LoadingStatus _status = LoadingStatus.NONE;
  int _page = 1;

  Future<List> fetchData(int page);

  @override
  void initState() {
    super.initState();
    loadMore();
  }

  void refresh() {
    items.clear();
    _page = 1;
    _status = LoadingStatus.NONE;
    loadMore();
  }

  void loadMore() {
    if (_status == LoadingStatus.NO_MORE || _status == LoadingStatus.LOADING) {
      return;
    }
    print("load more page: $_page");
    setState(() {
      _status = LoadingStatus.LOADING;
    });
    fetchData(_page).then((data) {
      print("load data: ${data.length}");
      if (data.isEmpty) {
        setState(() {
          _status = LoadingStatus.NO_MORE;
        });
      } else {
        _page++;
        if (mounted) {
          setState(() {
            _status = LoadingStatus.NONE;
            items.addAll(data);
            onLoadComplete();
          });
        }
      }
    }).catchError((e) {
      debugPrint(e.toString());
      if (mounted) {
        setState(() {
          _status = LoadingStatus.ERROR;
        });
        toast(e);
      }
    });
  }

  void onLoadComplete() {}

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_status == LoadingStatus.LOADING && items.isEmpty)
      return Center(
        child: CircularProgressIndicator(),
      );
    else
      return NotificationListener(
        onNotification: (notification) {
          if (notification.runtimeType == ScrollUpdateNotification) {
            var n = notification as ScrollUpdateNotification;
            if (_status != LoadingStatus.LOADING &&
                _status != LoadingStatus.ERROR &&
                n.metrics.extentAfter < 50) {
              loadMore();
            }
          }
          return true;
        },
        child: ListView.builder(
          itemCount: items.length + 1,
          itemBuilder: (c, i) {
            if (i == items.length) {
              return getWidgetByLoadingStatus(_status, loadMore);
            } else {
              return buildItem(context, i, items[i]);
            }
          },
        ),
      );
  }

  @override
  bool get wantKeepAlive => false;

  Widget buildItem(BuildContext context, int index, dynamic item);
}
