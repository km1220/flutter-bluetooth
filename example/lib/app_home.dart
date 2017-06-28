import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDumpRenderTree, debugDumpLayerTree, debugDumpSemanticsTree;
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_blue_example/app_configuration.dart';
import 'package:flutter_blue_example/app_strings.dart';
import 'package:flutter_blue_example/scan_devices_page.dart';

typedef void ModeUpdater(DisplayMode mode);

enum _StockMenuItem { autorefresh, refresh, speedUp, speedDown }
enum AppHomeTab { scanner, bonded }

class _NotImplementedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: const Text('Not Implemented'),
      content: const Text('This feature has not yet been implemented.'),
      actions: <Widget>[
        new FlatButton(
          onPressed: debugDumpApp,
          child: new Row(
            children: <Widget>[
              const Icon(
                Icons.dvr,
                size: 18.0,
              ),
              new Container(
                width: 8.0,
              ),
              const Text('DUMP APP TO CONSOLE'),
            ],
          ),
        ),
        new FlatButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('OH WELL'),
        ),
      ],
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome(this.stocks, this.symbols, this.configuration, this.updater);

  final Map<String, Object> stocks;
  final List<String> symbols;
  final AppConfiguration configuration;
  final ValueChanged<AppConfiguration> updater;

  @override
  AppHomeState createState() => new AppHomeState();
}

class AppHomeState extends State<AppHome> {

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  final TextEditingController _searchQuery = new TextEditingController();
  bool _autorefresh = false;

  void _handleSearchBegin() {
    ModalRoute.of(context).addLocalHistoryEntry(new LocalHistoryEntry(
      onRemove: () {
        setState(() {
          _isSearching = false;
          _searchQuery.clear();
        });
      },
    ));
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    Navigator.pop(context);
  }

  void _handleDisplayModeChange(DisplayMode value) {
    if (widget.updater != null)
      widget.updater(widget.configuration.copyWith(displayMode: value));
  }

  void _handleStockMenu(BuildContext context, _StockMenuItem value) {
    switch(value) {
      case _StockMenuItem.autorefresh:
        setState(() {
          _autorefresh = !_autorefresh;
        });
        break;
      case _StockMenuItem.refresh:
        showDialog<Null>(
            context: context,
            child: new _NotImplementedDialog()
        );
        break;
      case _StockMenuItem.speedUp:
        timeDilation /= 5.0;
        break;
      case _StockMenuItem.speedDown:
        timeDilation *= 5.0;
        break;
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return new Drawer(
      child: new ListView(
        children: <Widget>[
          const DrawerHeader(child: const Center(child: const Text('FlutterBlue'))),
          const ListTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: const Text('Devices'),
            selected: true,
          ),
          new ListTile(
            leading: const Icon(Icons.dvr),
            title: const Text('Dump App to Console'),
            onTap: () {
              try {
                debugDumpApp();
                debugDumpRenderTree();
                debugDumpLayerTree();
                debugDumpSemanticsTree();
              } catch (e, stack) {
                debugPrint('Exception while dumping app:\n$e\n$stack');
              }
            },
          ),
          const Divider(),
          new ListTile(
            leading: const Icon(Icons.brightness_high),
            title: const Text('Light mode'),
            trailing: new Radio<DisplayMode>(
              value: DisplayMode.light,
              groupValue: widget.configuration.displayMode,
              onChanged: _handleDisplayModeChange,
            ),
            onTap: () {
              _handleDisplayModeChange(DisplayMode.light);
            },
          ),
          new ListTile(
            leading: const Icon(Icons.brightness_low),
            title: const Text('Dark mode'),
            trailing: new Radio<DisplayMode>(
              value: DisplayMode.dark,
              groupValue: widget.configuration.displayMode,
              onChanged: _handleDisplayModeChange,
            ),
            onTap: () {
              _handleDisplayModeChange(DisplayMode.dark);
            },
          ),
          const Divider(),
          new ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: _handleShowSettings,
          ),
          new ListTile(
            leading: const Icon(Icons.help),
            title: const Text('About'),
            onTap: _handleShowAbout,
          ),
        ],
      ),
    );
  }

  void _handleShowSettings() {
    Navigator.popAndPushNamed(context, '/settings');
  }

  void _handleShowAbout() {
    showAboutDialog(context: context);
  }

  Widget buildAppBar() {
    return new AppBar(
      elevation: 0.0,
      title: new Text(AppStrings.of(context).devices()),
      actions: <Widget>[
        new IconButton(
          icon: const Icon(Icons.search),
          onPressed: _handleSearchBegin,
          tooltip: 'Search',
        ),
        new PopupMenuButton<_StockMenuItem>(
          onSelected: (_StockMenuItem value) { _handleStockMenu(context, value); },
          itemBuilder: (BuildContext context) => <PopupMenuItem<_StockMenuItem>>[
            new CheckedPopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.autorefresh,
              checked: _autorefresh,
              child: const Text('Autorefresh'),
            ),
            const PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.refresh,
              child: const Text('Refresh'),
            ),
            const PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.speedUp,
              child: const Text('Increase animation speed'),
            ),
            const PopupMenuItem<_StockMenuItem>(
              value: _StockMenuItem.speedDown,
              child: const Text('Decrease animation speed'),
            ),
          ],
        ),
      ],
      /*bottom: new TabBar(
        tabs: <Widget>[
          new Tab(text: AppStrings.of(context).scanner()),
          new Tab(text: AppStrings.of(context).bonded()),
        ],
      ),*/
    );
  }

  /*Iterable<Stock> _getStockList(Iterable<String> symbols) {
    return symbols.map((String symbol) => widget.stocks[symbol])
        .where((Stock stock) => stock != null);
  }

  Iterable<Stock> _filterBySearchQuery(Iterable<Stock> stocks) {
    if (_searchQuery.text.isEmpty)
      return stocks;
    final RegExp regexp = new RegExp(_searchQuery.text, caseSensitive: false);
    return stocks.where((Stock stock) => stock.symbol.contains(regexp));
  }

  void _buyStock(Stock stock) {
    setState(() {
      stock.percentChange = 100.0 * (1.0 / stock.lastSale);
      stock.lastSale += 1.0;
    });
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text("Purchased ${stock.symbol} for ${stock.lastSale}"),
      action: new SnackBarAction(
        label: "BUY MORE",
        onPressed: () {
          _buyStock(stock);
        },
      ),
    ));
  }

  Widget _buildStockList(BuildContext context, Iterable<Stock> stocks, AppHomeTab tab) {
    return new StockList(
      stocks: stocks.toList(),
      onAction: _buyStock,
      onOpen: (Stock stock) {
        Navigator.pushNamed(context, '/stock/${stock.symbol}');
      },
      onShow: (Stock stock) {
        _scaffoldKey.currentState.showBottomSheet<Null>((BuildContext context) => new StockSymbolBottomSheet(stock: stock));
      },
    );
  }

  Widget _buildStockTab(BuildContext context, AppHomeTab tab, List<String> stockSymbols) {
    return new Container(
      key: new ValueKey<AppHomeTab>(tab),
      child: _buildStockList(context, _filterBySearchQuery(_getStockList(stockSymbols)).toList(), tab),
    );
  }
  */

  Widget _buildScannerTab(BuildContext context, AppHomeTab tab) {
    return new ScanDevicesPage(
        key: new ValueKey<AppHomeTab>(tab),
        );
  }

  static const List<String> bondedSymbols = const <String>["AAPL","FIZZ", "FIVE", "FLAT", "ZINC", "ZNGA"];

  // TODO(abarth): Should we factor this into a SearchBar in the framework?
  Widget buildSearchBar() {
    return new AppBar(
      leading: new IconButton(
        icon: const Icon(Icons.arrow_back),
        color: Theme.of(context).accentColor,
        onPressed: _handleSearchEnd,
        tooltip: 'Back',
      ),
      title: new TextField(
        controller: _searchQuery,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search stocks',
        ),
      ),
      backgroundColor: Theme.of(context).canvasColor,
    );
  }

  void _handleCreateCompany() {
    showModalBottomSheet<Null>(
      context: context,
      builder: (BuildContext context) => new _CreateCompanySheet(),
    );
  }

  Widget buildFloatingActionButton() {
    return new FloatingActionButton(
      tooltip: 'Create company',
      child: const Icon(Icons.add),
      backgroundColor: Colors.redAccent,
      onPressed: _handleCreateCompany,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: 2,
      child: new Scaffold(
        key: _scaffoldKey,
        appBar: _isSearching ? buildSearchBar() : buildAppBar(),
        //floatingActionButton: buildFloatingActionButton(),
        drawer: _buildDrawer(context),
        body: new TabBarView(
          children: <Widget>[
            _buildScannerTab(context, AppHomeTab.scanner),
           // _buildStockTab(context, AppHomeTab.bonded, bondedSymbols),
          ],
        ),
      ),
    );
  }
}

class _CreateCompanySheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO(ianh): Fill this out.
    return new Column(
      children: <Widget>[
        const TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Company Name',
          ),
        ),
      ],
    );
  }
}
