/// Round brand-coloured bubble with the number of stations in a cluster.
abstract final class ClusterMarkerHtml {
  static String bubble(int count) {
    return '<div style="min-width:40px;height:40px;padding:0 8px;box-sizing:border-box;border-radius:999px;'
        'background:#00A86B;color:#fff;border:3px solid #fff;display:flex;align-items:center;'
        'justify-content:center;font:700 15px Pretendard,-apple-system,sans-serif;'
        'box-shadow:0 1px 5px rgba(0,0,0,.3);">$count</div>';
  }
}
