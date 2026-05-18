import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:bus_tracking/my_app_bar.dart';
import 'package:bus_tracking/my_drawer.dart';
import 'package:bus_tracking/utils/constants.dart';
import 'package:bus_tracking/services/gps_websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const double _kSpeedMps    = 12.0;
const String _kValhallaUrl = 'https://valhalla1.openstreetmap.de/route';
const String _kOsrmUrl     = 'https://router.project-osrm.org/route/v1/driving';

/// Centre de secours sur la Tunisie (Sofrecom - Lac 1)
const LatLng _kTunisiaCenter = LatLng(36.831585, 10.232803);

/// Waypoints définis par bus ID.
/// Utilisés à la place des données backend pour garantir le bon tracé
/// de chaque trajet (départ/arrivée corrects), indépendamment de la BDD.
const Map<int, List<LatLng>> _kHardcodedWaypoints = {
  1: [
    LatLng(36.705199, 10.407781), // Borj Cedriya (départ)
    LatLng(36.713843, 10.368674), // Hammem Chatt
    LatLng(36.727068, 10.336807), // Hammem Lif
    LatLng(36.736568, 10.313460), // Ezzahra lycée
    LatLng(36.740769, 10.302511), // Ezzahra ville
    LatLng(36.756550, 10.278947), // Radès
    LatLng(36.764836, 10.277623), // Pont Radès
    LatLng(36.772570, 10.287141), // Radès chatt
    LatLng(36.801808, 10.195353), // TGM
    LatLng(36.809757, 10.193572), // Lac 0
    LatLng(36.831374, 10.232228), // Lac 1 (arrivée)
  ],
  6: [
    LatLng(36.705199, 10.407781), // Borj Cedriya (départ)
    LatLng(36.713843, 10.368674), // Hammem Chatt
    LatLng(36.727068, 10.336807), // Hammem Lif
    LatLng(36.736568, 10.313460), // Ezzahra lycée
    LatLng(36.740769, 10.302511), // Ezzahra ville
    LatLng(36.756550, 10.278947), // Radès
    LatLng(36.764836, 10.277623), // Pont Radès
    LatLng(36.772570, 10.287141), // Radès chatt
    LatLng(36.801808, 10.195353), // TGM
    LatLng(36.809757, 10.193572), // Lac 0
    LatLng(36.831374, 10.232228), // Lac 1 (arrivée)
  ],
  7: [
    LatLng(36.862000, 10.193500), // Ariana (départ)
    LatLng(36.849500, 10.198000), // Cité Ettadhamen
    LatLng(36.840200, 10.213000), // Centre Urbain Nord
    LatLng(36.831585, 10.232803), // Sofrecom (arrivée)
  ],
  8: [
    LatLng(37.269527,  9.874099), // Bizerte (départ)
    LatLng(37.264961,  9.885155), // Bizerte Zarzouna
    LatLng(36.831585, 10.232803), // Sofrecom (arrivée)
  ],
};

/// Noms des stations par bus — miroir de stationNames dans BUS_ROUTES (web)
const Map<int, List<String>> _kStationNames = {
  1: ['Borj Cedriya','Hammem Chatt','Hammem Lif','Ezzahra lycée','Ezzahra ville','Radès','Pont Radès','Radès chatt','TGM','Lac 0','Lac 1'],
  6: ['Borj Cedriya','Hammem Chatt','Hammem Lif','Ezzahra lycée','Ezzahra ville','Radès','Pont Radès','Radès chatt','TGM','Lac 0','Lac 1'],
  7: ['Ariana','Cité Ettadhamen','Centre Urbain Nord','Sofrecom'],
  8: ['Bizerte','Bizerte Zarzouna','Sofrecom'],
};

/// Noms de départ/arrivée par bus — miroir de BUS_ROUTES.depName/destName (web)
const Map<int, Map<String, String>> _kBusRouteInfo = {
  1: {'dep': 'Borj Cedriya',  'dest': 'Lac 1 (Berges du Lac)'},
  6: {'dep': 'Borj Cedriya',  'dest': 'Lac 1 (Berges du Lac)'},
  7: {'dep': 'Ariana',        'dest': 'Sofrecom'},
  8: {'dep': 'Bizerte',       'dest': 'Sofrecom'},
};

/// Routes pré-calculées OSRM — identiques pixel pour pixel au tracé web Angular.
/// Générées via : router.project-osrm.org avec les 4 waypoints du bus 7.
/// Évite tout appel réseau (CORS/timeout) et garantit le même tracé sur toutes
/// les plateformes (APK Android, Flutter web, émulateur).
const Map<int, List<LatLng>> _kPrecomputedRoutes = {
  7: [ // Bus 7 : Ariana → Sofrecom — 383 points OSRM
    LatLng(36.862049,10.193622),LatLng(36.861596,10.193906),LatLng(36.861766,10.194311),
    LatLng(36.861873,10.194568),LatLng(36.861966,10.194786),LatLng(36.862065,10.195036),
    LatLng(36.862263,10.195546),LatLng(36.86225,10.19555),LatLng(36.862238,10.195559),
    LatLng(36.86223,10.195573),LatLng(36.862227,10.19559),LatLng(36.862228,10.195607),
    LatLng(36.862235,10.195622),LatLng(36.861973,10.195828),LatLng(36.86184,10.195939),
    LatLng(36.861691,10.196063),LatLng(36.860866,10.196731),LatLng(36.860368,10.197104),
    LatLng(36.860337,10.197137),LatLng(36.860308,10.197181),LatLng(36.860281,10.197228),
    LatLng(36.860203,10.197358),LatLng(36.860119,10.197501),LatLng(36.86005,10.197514),
    LatLng(36.859594,10.197889),LatLng(36.859452,10.197903),LatLng(36.859413,10.197905),
    LatLng(36.859376,10.197897),LatLng(36.859348,10.197888),LatLng(36.85933,10.197875),
    LatLng(36.859316,10.197861),LatLng(36.8593,10.197841),LatLng(36.859298,10.197829),
    LatLng(36.859279,10.197757),LatLng(36.859248,10.197642),LatLng(36.859097,10.197079),
    LatLng(36.859044,10.197101),LatLng(36.859125,10.197453),LatLng(36.859115,10.197597),
    LatLng(36.859107,10.197629),LatLng(36.859096,10.197647),LatLng(36.859079,10.197659),
    LatLng(36.859046,10.197663),LatLng(36.859016,10.197659),LatLng(36.858929,10.197623),
    LatLng(36.85844,10.19742),LatLng(36.85712,10.196871),LatLng(36.856833,10.196686),
    LatLng(36.856669,10.196575),LatLng(36.856202,10.196251),LatLng(36.85593,10.19612),
    LatLng(36.85557,10.195992),LatLng(36.855349,10.195904),LatLng(36.855172,10.195888),
    LatLng(36.855166,10.195877),LatLng(36.855126,10.195836),LatLng(36.855076,10.195822),
    LatLng(36.855004,10.195859),LatLng(36.854925,10.195857),LatLng(36.853928,10.195836),
    LatLng(36.853671,10.195831),LatLng(36.85359,10.195827),LatLng(36.852695,10.195784),
    LatLng(36.852181,10.19575),LatLng(36.852038,10.195679),LatLng(36.851817,10.195657),
    LatLng(36.851676,10.195642),LatLng(36.85153,10.195621),LatLng(36.85148,10.195606),
    LatLng(36.851437,10.195574),LatLng(36.851402,10.19555),LatLng(36.851351,10.195515),
    LatLng(36.851306,10.195483),LatLng(36.851011,10.19546),LatLng(36.850927,10.195477),
    LatLng(36.850927,10.195566),LatLng(36.850922,10.195606),LatLng(36.850918,10.195694),
    LatLng(36.850936,10.195724),LatLng(36.850953,10.195851),LatLng(36.850956,10.195918),
    LatLng(36.850942,10.196009),LatLng(36.850922,10.196115),LatLng(36.850878,10.196225),
    LatLng(36.850838,10.196409),LatLng(36.850817,10.196694),LatLng(36.850748,10.196815),
    LatLng(36.850725,10.196875),LatLng(36.850718,10.196938),LatLng(36.850697,10.196946),
    LatLng(36.850558,10.19693),LatLng(36.849974,10.196793),LatLng(36.849952,10.19677),
    LatLng(36.849925,10.196757),LatLng(36.849896,10.196758),LatLng(36.849868,10.196772),
    LatLng(36.849844,10.196801),LatLng(36.849832,10.19684),LatLng(36.849833,10.196882),
    LatLng(36.849848,10.19692),LatLng(36.849857,10.196931),LatLng(36.849721,10.197795),
    LatLng(36.849682,10.198044),LatLng(36.849632,10.198366),LatLng(36.849533,10.199001),
    LatLng(36.849503,10.199088),LatLng(36.849463,10.199151),LatLng(36.849192,10.199395),
    LatLng(36.848509,10.200008),LatLng(36.847906,10.20053),LatLng(36.847861,10.200465),
    LatLng(36.847802,10.200422),LatLng(36.847734,10.200406),LatLng(36.847526,10.199875),
    LatLng(36.84722,10.199085),LatLng(36.847025,10.198625),LatLng(36.847077,10.198524),
    LatLng(36.8471,10.198407),LatLng(36.847091,10.198287),LatLng(36.847077,10.198234),
    LatLng(36.847055,10.198184),LatLng(36.846986,10.19809),LatLng(36.846896,10.198031),
    LatLng(36.846795,10.198015),LatLng(36.846449,10.197151),LatLng(36.846367,10.196949),
    LatLng(36.846268,10.196706),LatLng(36.846071,10.196225),LatLng(36.846085,10.196174),
    LatLng(36.846154,10.196061),LatLng(36.846202,10.195999),LatLng(36.846247,10.195944),
    LatLng(36.846389,10.195831),LatLng(36.847313,10.195212),LatLng(36.848049,10.194667),
    LatLng(36.84809,10.194641),LatLng(36.848117,10.194629),LatLng(36.848172,10.194608),
    LatLng(36.848241,10.194672),LatLng(36.848321,10.194704),LatLng(36.848405,10.194703),
    LatLng(36.848484,10.194667),LatLng(36.84853,10.194626),LatLng(36.848581,10.194548),
    LatLng(36.848597,10.194508),LatLng(36.848614,10.194439),LatLng(36.848616,10.194403),
    LatLng(36.848608,10.194302),LatLng(36.848658,10.194271),LatLng(36.848702,10.194242),
    LatLng(36.848758,10.194207),LatLng(36.84923,10.1939),LatLng(36.849325,10.193844),
    LatLng(36.849362,10.193823),LatLng(36.849408,10.193793),LatLng(36.849491,10.193746),
    LatLng(36.849522,10.193769),LatLng(36.849556,10.193781),LatLng(36.849568,10.193783),
    LatLng(36.849607,10.193781),LatLng(36.849644,10.193765),LatLng(36.849676,10.193738),
    LatLng(36.849712,10.193677),LatLng(36.849756,10.193629),LatLng(36.8498,10.193585),
    LatLng(36.850121,10.193351),LatLng(36.850217,10.193278),LatLng(36.850473,10.193086),
    LatLng(36.85058,10.193039),LatLng(36.850687,10.193014),LatLng(36.850779,10.193038),
    LatLng(36.850866,10.193078),LatLng(36.850925,10.193141),LatLng(36.850968,10.193215),
    LatLng(36.851019,10.193384),LatLng(36.851043,10.193503),LatLng(36.851081,10.193812),
    LatLng(36.8511,10.194165),LatLng(36.851146,10.195048),LatLng(36.851138,10.195681),
    LatLng(36.851095,10.196358),LatLng(36.851022,10.197075),LatLng(36.850924,10.197811),
    LatLng(36.850767,10.198722),LatLng(36.850744,10.199039),LatLng(36.850695,10.199368),
    LatLng(36.85025,10.201786),LatLng(36.850075,10.202652),LatLng(36.849958,10.203417),
    LatLng(36.849913,10.203676),LatLng(36.849541,10.205601),LatLng(36.849113,10.208421),
    LatLng(36.848733,10.210558),LatLng(36.848551,10.211525),LatLng(36.84839,10.212253),
    LatLng(36.848354,10.212419),LatLng(36.848309,10.212581),LatLng(36.848258,10.21274),
    LatLng(36.848199,10.212895),LatLng(36.848133,10.213046),LatLng(36.848061,10.213192),
    LatLng(36.847965,10.213338),LatLng(36.84787,10.213462),LatLng(36.847759,10.213578),
    LatLng(36.84764,10.213672),LatLng(36.847519,10.213751),LatLng(36.846561,10.214326),
    LatLng(36.846351,10.214446),LatLng(36.846224,10.214512),LatLng(36.846096,10.214573),
    LatLng(36.845966,10.214631),LatLng(36.845836,10.214684),LatLng(36.845704,10.214733),
    LatLng(36.845532,10.214791),LatLng(36.845358,10.214844),LatLng(36.845183,10.214888),
    LatLng(36.844988,10.214932),LatLng(36.844792,10.214967),LatLng(36.844594,10.214994),
    LatLng(36.844393,10.215011),LatLng(36.844174,10.215016),LatLng(36.843769,10.214992),
    LatLng(36.843692,10.214984),LatLng(36.843616,10.214972),LatLng(36.84354,10.214957),
    LatLng(36.842591,10.214727),LatLng(36.840812,10.214246),LatLng(36.839317,10.213814),
    LatLng(36.839059,10.213737),LatLng(36.838997,10.213677),LatLng(36.83894,10.213609),
    LatLng(36.838888,10.213535),LatLng(36.838842,10.213456),LatLng(36.838801,10.213372),
    LatLng(36.838785,10.21331),LatLng(36.838767,10.213249),LatLng(36.838746,10.213189),
    LatLng(36.83878,10.213204),LatLng(36.838807,10.213218),LatLng(36.838824,10.213235),
    LatLng(36.838842,10.213257),LatLng(36.838858,10.21328),LatLng(36.838941,10.213387),
    LatLng(36.838958,10.213403),LatLng(36.838978,10.213413),LatLng(36.839002,10.213422),
    LatLng(36.839024,10.213429),LatLng(36.839066,10.213433),LatLng(36.839143,10.213435),
    LatLng(36.839379,10.213451),LatLng(36.839551,10.213457),LatLng(36.83973,10.213462),
    LatLng(36.84006,10.213483),LatLng(36.840125,10.21349),LatLng(36.840166,10.213494),
    LatLng(36.840199,10.213498),LatLng(36.840276,10.213517),LatLng(36.840359,10.213541),
    LatLng(36.840854,10.213685),LatLng(36.840841,10.213777),LatLng(36.840818,10.213848),
    LatLng(36.840788,10.213916),LatLng(36.840751,10.213978),LatLng(36.840707,10.214033),
    LatLng(36.840659,10.21408),LatLng(36.839503,10.213788),LatLng(36.839456,10.213784),
    LatLng(36.839409,10.213787),LatLng(36.839362,10.213797),LatLng(36.839317,10.213814),
    LatLng(36.839059,10.213737),LatLng(36.838645,10.213624),LatLng(36.835821,10.212856),
    LatLng(36.835675,10.212805),LatLng(36.835606,10.212775),LatLng(36.835541,10.212738),
    LatLng(36.835478,10.212692),LatLng(36.83542,10.21264),LatLng(36.835389,10.212622),
    LatLng(36.835364,10.212611),LatLng(36.835316,10.212596),LatLng(36.835266,10.212589),
    LatLng(36.835216,10.21259),LatLng(36.835167,10.2126),LatLng(36.83511,10.212607),
    LatLng(36.834963,10.2126),LatLng(36.834805,10.212586),LatLng(36.83463,10.212566),
    LatLng(36.834456,10.212533),LatLng(36.834158,10.212444),LatLng(36.833719,10.212365),
    LatLng(36.832261,10.212098),LatLng(36.831907,10.212103),LatLng(36.831597,10.212135),
    LatLng(36.831278,10.212192),LatLng(36.831038,10.212259),LatLng(36.830816,10.212346),
    LatLng(36.830422,10.212492),LatLng(36.830332,10.212522),LatLng(36.830015,10.212661),
    LatLng(36.829789,10.212734),LatLng(36.829732,10.212697),LatLng(36.82967,10.212679),
    LatLng(36.829605,10.21268),LatLng(36.829543,10.212701),LatLng(36.829486,10.212741),
    LatLng(36.829439,10.212797),LatLng(36.829405,10.212866),LatLng(36.829382,10.212976),
    LatLng(36.829391,10.213088),LatLng(36.829429,10.21319),LatLng(36.829494,10.21327),
    LatLng(36.829576,10.213317),LatLng(36.829666,10.213326),LatLng(36.829773,10.2135),
    LatLng(36.829904,10.213699),LatLng(36.830031,10.213932),LatLng(36.830047,10.213964),
    LatLng(36.830136,10.214139),LatLng(36.830223,10.214345),LatLng(36.830338,10.214601),
    LatLng(36.830461,10.214881),LatLng(36.830569,10.215157),LatLng(36.830664,10.215385),
    LatLng(36.830839,10.21587),LatLng(36.831101,10.216602),LatLng(36.83109,10.216643),
    LatLng(36.831084,10.216686),LatLng(36.830765,10.216934),LatLng(36.830617,10.217055),
    LatLng(36.830534,10.217153),LatLng(36.830462,10.217317),LatLng(36.830117,10.218193),
    LatLng(36.82987,10.218848),LatLng(36.829832,10.218982),LatLng(36.82983,10.219112),
    LatLng(36.829845,10.219228),LatLng(36.830116,10.220301),LatLng(36.830381,10.221532),
    LatLng(36.830437,10.221828),LatLng(36.830474,10.222093),LatLng(36.830557,10.222709),
    LatLng(36.830607,10.223193),LatLng(36.830645,10.223557),LatLng(36.830658,10.223681),
    LatLng(36.830668,10.223805),LatLng(36.830704,10.224262),LatLng(36.830721,10.224691),
    LatLng(36.830723,10.225031),LatLng(36.830709,10.22532),LatLng(36.830685,10.225488),
    LatLng(36.830652,10.225688),LatLng(36.830604,10.225869),LatLng(36.83056,10.226013),
    LatLng(36.830534,10.226072),LatLng(36.830504,10.22614),LatLng(36.830421,10.22623),
    LatLng(36.830364,10.226256),LatLng(36.830316,10.226304),LatLng(36.830284,10.226369),
    LatLng(36.830272,10.226444),LatLng(36.83028,10.22652),LatLng(36.830259,10.226616),
    LatLng(36.830247,10.226717),LatLng(36.830231,10.226841),LatLng(36.830209,10.226939),
    LatLng(36.830178,10.227047),LatLng(36.830126,10.22721),LatLng(36.830087,10.227339),
    LatLng(36.830071,10.227414),LatLng(36.830066,10.227477),LatLng(36.830067,10.227553),
    LatLng(36.830075,10.227607),LatLng(36.830092,10.227645),LatLng(36.830115,10.227673),
    LatLng(36.830121,10.227693),LatLng(36.830545,10.229071),LatLng(36.830731,10.229675),
    LatLng(36.831086,10.230907),LatLng(36.831271,10.231553),LatLng(36.831298,10.231643),
    LatLng(36.831455,10.232161),LatLng(36.831633,10.232781),
  ],
};

/// Vérifie que des coordonnées lat/lng sont géographiquement valides
bool _isCoordsValid(double lat, double lng) {
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180
      && !(lat == 0.0 && lng == 0.0); // (0,0) = mer, clairement invalide
}

/// Vérifie que les coordonnées correspondent à la zone Tunisie (+/- marge)
bool _isInTunisiaRegion(double lat, double lng) {
  return lat >= 30.0 && lat <= 38.5 && lng >= 7.0 && lng <= 12.5;
}

class HomePage extends StatefulWidget {
  final String matricule;
  final String nom;
  final String prenom;
  final int id;
  final int id_st;
  final int id_b;

  const HomePage({
    Key? key,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.id,
    required this.id_st,
    required this.id_b,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> _stations = [];
  List<Marker> _stationMarkers = [];
  LatLng? _salarieStation;

  List<LatLng> _routePoints   = [];
  List<LatLng> _traveledPoints = [];
  bool _routeLoading = false;

  LatLng? _busPosition;
  double  _bearing = 0.0;
  bool    _busPositionUnavailable = false;

  int?    _etaMinutes;
  double? _distanceKm;

  GpsWebSocketService? _gpsWs;
  bool _realGpsActive = false;

  Timer?    _simTimer;
  DateTime? _simLastTick;
  int       _simSegIdx = 0;
  double    _simSegT   = 0.0;

  DateTime? _pauseTime;
  /// Verrou anti-resync concurrent : une seule resynchronisation active à la fois
  bool _isResyncing = false;

  /// Vitesse courante du bus (km/h) reçue par WebSocket
  double? _busSpeed;
  /// Heure d'arrivée estimée (HH:mm) calculée depuis _etaMinutes
  String? _etaArrivalTime;

  final MapController _mapController = MapController();

  /// Quand true, la carte suit automatiquement le bus.
  /// Devient false quand l'utilisateur fait un geste (pinch/scroll/drag) :
  /// la carte reste libre pendant 8 s puis reprend le suivi automatiquement.
  bool   _followBus = true;
  Timer? _followBusResumeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pré-initialiser depuis les données codées pour les bus connus :
    // la carte s'affiche immédiatement sans attendre le backend (= comportement web)
    if (_kHardcodedWaypoints.containsKey(widget.id_b)) {
      _stationMarkers = _buildHardcodedMarkers(widget.id_b);
      _stations = List.generate(
        _kHardcodedWaypoints[widget.id_b]!.length,
        (i) => <String, dynamic>{'idx': i},
      );
      _isLoading = false;
      // Afficher l'icône bus immédiatement au premier waypoint (pas d'attente async)
      _busPosition = _kHardcodedWaypoints[widget.id_b]!.first;
      _busPositionUnavailable = false;
      // Démarrer le chargement de la route immédiatement (sans attendre le backend).
      _loadRoute(_kHardcodedWaypoints[widget.id_b]!);
    }
    _fetchLatestPosition();
    _fetchSalarieStation();
    _fetchStations();
    _initWebSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsWs?.disconnect();
    _simTimer?.cancel();
    _followBusResumeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // 1. Stopper proprement la simulation avant de passer en arrière-plan
      _stopSimulation();
      _pauseTime = DateTime.now();
      debugPrint('[Lifecycle] App en arrière-plan — simulation stoppée');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[Lifecycle] App revenue — resynchronisation...');

      // 2. Stopper toute simulation résiduelle (sécurité)
      _stopSimulation();

      // 3. Fast-forward local (instantané) si la route est chargée
      if (_pauseTime != null &&
          _routePoints.length >= 2 &&
          !_realGpsActive) {
        final elapsedMs =
            DateTime.now().difference(_pauseTime!).inMilliseconds.toDouble();
        _fastForwardSimulation(elapsedMs);
      }
      _pauseTime = null;

      // 4. Relancer la simulation IMMÉDIATEMENT (sans attendre le réseau)
      // _resyncPosition() peut retourner prématurément si données backend
      // trop anciennes ou hors zone — la simulation serait alors orpheline.
      if (!_realGpsActive && _routePoints.length >= 2) {
        _startSimulation();
        debugPrint('[Lifecycle] Simulation relancee au retour en avant-plan');
      }

      // 5. Resync réseau (async) — repositionnera le bus sur le bon segment
      _resyncPosition();
    }
  }

  void _initWebSocket() {
    _gpsWs = GpsWebSocketService(
      busId: widget.id_b,
      onPosition: (data) {
        if (!mounted) return;
        final lat     = (data['latitude']  as num).toDouble();
        final lng     = (data['longitude'] as num).toDouble();
        final bearing = (data['bearing']   as num?)?.toDouble() ?? _bearing;
        _onGpsData(LatLng(lat, lng), bearing, (data['speed'] as num?)?.toDouble() ?? 0);
      },
      onConnected: () => debugPrint('[GPS-WS] Connecte pour bus ${widget.id_b}'),
      onError: (e) => debugPrint('[GPS-WS] Erreur: $e'),
    );
    _gpsWs!.connect();
  }

  void _onGpsData(LatLng raw, double bearing, double speed) {
    // Valider les coordonnées avant d'appliquer (comme dans _fetchLatestPosition)
    if (!_isCoordsValid(raw.latitude, raw.longitude) ||
        !_isInTunisiaRegion(raw.latitude, raw.longitude)) {
      debugPrint('[WS] Coordonnées invalides ignorées: ${raw.latitude}, ${raw.longitude}');
      return;
    }
    // Rejeter les positions trop éloignées de la route définie (données GPS périmées)
    final hw = _kHardcodedWaypoints[widget.id_b];
    if (hw != null && hw.isNotEmpty) {
      final minDist = hw.map((p) => _distanceBetween(raw, p)).reduce(min);
      if (minDist > 3000) {
        debugPrint('[WS] Position hors trajet (${minDist.toStringAsFixed(0)} m) — ignorée');
        return;
      }
    }
    final snapped = _snapToRoute(raw);
    if (!_realGpsActive) {
      _realGpsActive = true;
      _stopSimulation();
      _traveledPoints.clear(); // Réinitialiser l'historique de simulation
    }
    if (mounted) {
      setState(() {
        _busPosition            = snapped;
        _bearing                = bearing;
        _busPositionUnavailable = false;
        _traveledPoints.add(snapped);
        if (_traveledPoints.length > 500) _traveledPoints.removeAt(0);
        if (speed > 0) _busSpeed = speed;
      });
    }
    _centerIfNeeded(snapped);
    _fetchEta(snapped.latitude, snapped.longitude);
  }

  Future<void> _fetchLatestPosition() async {
    try {
      final res = await http
          .get(Uri.parse('$kBackendBaseUrl/gps/bus/${widget.id_b}/latest'))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 && res.body.trimLeft().startsWith('{')) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {
          if (mounted) setState(() => _busPositionUnavailable = true);
          return;
        }
        final lat  = (data['latitude']  as num).toDouble();
        final lng  = (data['longitude'] as num).toDouble();
        debugPrint('[fetchLatestPosition] Reu du backend: lat=$lat, lng=$lng');

        if (!_isCoordsValid(lat, lng)) {
          debugPrint('[fetchLatestPosition] ⚠️ Coordonnées invalides (lat=$lat, lng=$lng) — ignorées');
          if (mounted) setState(() => _busPositionUnavailable = true);
          return;
        }
        if (!_isInTunisiaRegion(lat, lng)) {
          debugPrint('[fetchLatestPosition] ⚠️ Hors Tunisie (lat=$lat, lng=$lng) — ignorées');
          if (mounted) setState(() => _busPositionUnavailable = true);
          return;
        }
        // Rejeter les positions trop éloignées de la route définie
        final hw = _kHardcodedWaypoints[widget.id_b];
        if (hw != null && hw.isNotEmpty) {
          final pos = LatLng(lat, lng);
          final minDist = hw.map((p) => _distanceBetween(pos, p)).reduce(min);
          if (minDist > 3000) {
            debugPrint('[fetchLatestPosition] ⚠️ Position hors trajet (${minDist.toStringAsFixed(0)} m) — ignorée');
            if (mounted) setState(() => _busPositionUnavailable = true);
            return;
          }
        }

        final ts   = DateTime.tryParse(data['timestamp']?.toString() ?? '');
        final age  = ts != null
            ? DateTime.now().difference(ts).inMilliseconds
            : 999999;
        if (age > 600000) {
          debugPrint('[fetchLatestPosition] Position trop ancienne (${age ~/ 1000}s) — ignorée');
          return;
        }

        if (mounted) {
          setState(() {
            _busPosition            = LatLng(lat, lng);
            _bearing                = (data['bearing'] as num?)?.toDouble() ?? 0;
            _busPositionUnavailable = false;
          });
          debugPrint('[fetchLatestPosition] ✅ Position bus: lat=$lat, lng=$lng (il y a ${age ~/ 1000}s)');
        }
        _fetchEta(lat, lng);
        return;
      }

      final res2 = await http.get(
          Uri.parse('$kBackendBaseUrl/buses/${widget.id_b}'));
      if (res2.statusCode == 200 && res2.body.trimLeft().startsWith('{')) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(res2.body) as Map<String, dynamic>;
        } catch (_) {
          if (mounted) setState(() => _busPositionUnavailable = true);
          return;
        }
        final lat2 = (data['latitude']  as num).toDouble();
        final lng2 = (data['longitude'] as num).toDouble();
        debugPrint('[fetchLatestPosition] Fallback bus: lat=$lat2, lng=$lng2');
        if (_isCoordsValid(lat2, lng2) && _isInTunisiaRegion(lat2, lng2)) {
          if (mounted) {
            setState(() {
              _busPosition = LatLng(lat2, lng2);
              _busPositionUnavailable = false;
            });
          }
        } else {
          if (mounted) setState(() => _busPositionUnavailable = true);
        }
      } else if (res2.statusCode == 404) {
        if (mounted) setState(() => _busPositionUnavailable = true);
      }
    } catch (e) {
      debugPrint('[fetchLatestPosition] Erreur: $e');
    }
  }

  Future<void> _resyncPosition() async {
    // Verrou : ignorer si une resync est déjà en cours
    if (_isResyncing || !mounted) return;
    _isResyncing = true;
    try {
      final res = await http
          .get(Uri.parse('$kBackendBaseUrl/gps/bus/${widget.id_b}/latest'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return;
      if (!res.body.trimLeft().startsWith('{')) return;

      Map<String, dynamic> data;
      try {
        data = jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) { return; }
      final lat  = (data['latitude']  as num).toDouble();
      final lng  = (data['longitude'] as num).toDouble();
      final ts   = DateTime.tryParse(data['timestamp']?.toString() ?? '');
      final age  = ts != null
          ? DateTime.now().difference(ts).inMilliseconds
          : 999999;
      if (age > 600000) return;

      // Rejeter les positions trop éloignées de la route définie (données périmées)
      final hwR = _kHardcodedWaypoints[widget.id_b];
      if (hwR != null && hwR.isNotEmpty) {
        final rawPos = LatLng(lat, lng);
        final minDist = hwR.map((p) => _distanceBetween(rawPos, p)).reduce(min);
        if (minDist > 3000) {
          debugPrint('[Resync] Position hors trajet (${minDist.toStringAsFixed(0)} m) — ignorée');
          return;
        }
      }

      // Snap sur la route puis mise à jour du marker
      final pos     = _snapToRoute(LatLng(lat, lng));
      final bearing = (data['bearing'] as num?)?.toDouble() ?? _bearing;

      if (!mounted) return;
      setState(() {
        _busPosition = pos;
        _bearing     = bearing;
        _traveledPoints.add(pos);
      });
      _centerIfNeeded(pos);

      // Redémarrage simulation depuis le bon index (si pas de GPS réel)
      if (!_realGpsActive && _routePoints.length >= 2) {
        _stopSimulation();              // arrêt propre avant tout
        _simSegIdx = _findNearestSegment(pos);
        _simSegT   = 0.0;
        _startSimulation();            // redémarrage depuis la bonne position
      }

      debugPrint('[Resync] OK $lat, $lng (il y a ${age ~/ 1000}s) — index $_simSegIdx/${_routePoints.length}');
    } catch (e) {
      debugPrint('[Resync] Erreur: $e');
    } finally {
      _isResyncing = false;
      // Garantie : si toutes les données backend ont été rejetées (trop anciennes,
      // hors zone, erreur réseau) et que le timer est mort, relancer la simulation.
      // Sans ce filet, les returns prématurés ci-dessus laissent le bus figé.
      if (!_realGpsActive &&
          _routePoints.length >= 2 &&
          _simTimer == null &&
          mounted) {
        _startSimulation();
        debugPrint('[Resync] Simulation relancee (fallback — donnees backend rejetees)');
      }
    }
  }

  /// Construit les marqueurs de stations depuis les waypoints codés.
  /// Miroir des icônes DEPARTURE_ICON / DESTINATION_ICON du web :
  /// vert = départ, rouge = arrivée, orange = intermédiaire.
  List<Marker> _buildHardcodedMarkers(int busId) {
    final wps   = _kHardcodedWaypoints[busId] ?? [];
    final names = _kStationNames[busId] ?? [];
    final len   = wps.length;
    return wps.asMap().entries.map<Marker>((e) {
      final idx     = e.key;
      final pt      = e.value;
      final isFirst = idx == 0;
      final isLast  = idx == len - 1;
      final name    = idx < names.length ? names[idx] : 'Arrêt ${idx + 1}';
      return Marker(
        width: 36, height: 36,
        point: pt,
        child: Tooltip(
          message: isFirst ? 'Départ — $name'
              : isLast    ? 'Arrivée — $name'
              : name,
          child: Icon(
            isFirst ? Icons.trip_origin
                : isLast ? Icons.flag
                : Icons.circle,
            color: isFirst ? const Color(0xFF00c853)
                : isLast   ? const Color(0xFFe53935)
                : const Color(0xFFff8f00),
            size: 28,
          ),
        ),
      );
    }).toList();
  }

  Future<void> _fetchSalarieStation() async {
    try {
      final res = await http.get(
          Uri.parse('$kBackendBaseUrl/stations/${widget.id_st}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          // DB has lat/lng columns swapped: 'longitude' field = actual lat, 'latitude' field = actual lng
          setState(() => _salarieStation = LatLng(
              (data['longitude'] as num).toDouble(),
              (data['latitude']  as num).toDouble()));
        }
      }
    } catch (e) {
      debugPrint('[fetchSalarieStation] $e');
    }
  }

  Future<void> _fetchStations() async {
    // ── Étape 1 : essayer l'endpoint partagé /buses/{id}/route ──────────────
    // Source de vérité commune avec l'application web Angular.
    // Si le backend retourne une config valide (≥2 waypoints en Tunisie),
    // on l'utilise directement et on court-circuite le reste de la méthode.
    try {
      final routeRes = await http
          .get(Uri.parse('$kBackendBaseUrl/buses/${widget.id_b}/route'))
          .timeout(const Duration(seconds: 5));
      debugPrint('[fetchStations] /buses/${widget.id_b}/route → ${routeRes.statusCode}');

      if (routeRes.statusCode == 200 && routeRes.body.trimLeft().startsWith('{')) {
        final routeData = jsonDecode(routeRes.body) as Map<String, dynamic>;
        final rawWps = routeData['waypoints'] as List<dynamic>?;

        if (rawWps != null && rawWps.length >= 2) {
          final apiWaypoints = rawWps.map<LatLng>((w) {
            final lat = (w['lat'] as num).toDouble();
            final lng = (w['lng'] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final apiMarkers = rawWps.asMap().entries.map<Marker>((e) {
            final idx  = e.key;
            final name = e.value['name'] as String? ?? 'Arrêt ${idx + 1}';
            final lat  = (e.value['lat'] as num).toDouble();
            final lng  = (e.value['lng'] as num).toDouble();
            return Marker(
              width: 32, height: 32,
              point: LatLng(lat, lng),
              child: Tooltip(
                message: name,
                child: Icon(
                  idx == 0               ? Icons.trip_origin
                      : idx == rawWps.length - 1 ? Icons.flag
                      : Icons.location_pin,
                  color: idx == 0               ? Colors.green
                      : idx == rawWps.length - 1 ? Colors.red
                      : Colors.orange,
                  size: 28,
                ),
              ),
            );
          }).toList();

          if (mounted) {
            setState(() {
              _stations       = rawWps.asMap().entries.map((e) => <String, dynamic>{'idx': e.key}).toList();
              _stationMarkers = apiMarkers;
              _isLoading      = false;
            });
          }
          debugPrint('[fetchStations] Route API : ${apiWaypoints.length} waypoints — '
              '${routeData['depName']} -> ${routeData['destName']}');
          await _loadRoute(apiWaypoints);
          return; // ← court-circuit : pas besoin du fallback /tragets/bus/{id}
        }
      }
    } catch (e) {
      debugPrint('[fetchStations] /buses/${widget.id_b}/route erreur : $e');
    }

    // ── Étape 2 (fallback) : ancienne logique /tragets/bus/{id} ─────────────
    try {
      // Primary: get route via bus ID (directly linked trajet — most reliable)
      http.Response res;
      if (widget.id_b > 0) {
        res = await http.get(
          Uri.parse('$kBackendBaseUrl/tragets/bus/${widget.id_b}'),
          headers: {'Content-Type': 'application/json'},
        );
        debugPrint('[fetchStations] /tragets/bus/${widget.id_b} → ${res.statusCode}');
      } else {
        res = http.Response('[]', 404);
      }

      // Fallback: get route via salarie station ID
      if (res.statusCode != 200 && widget.id_st > 0) {
        debugPrint('[fetchStations] Fallback → /tragets/stations/${widget.id_st}');
        res = await http.get(
          Uri.parse('$kBackendBaseUrl/tragets/stations/${widget.id_st}'),
          headers: {'Content-Type': 'application/json'},
        );
        debugPrint('[fetchStations] /tragets/stations/${widget.id_st} → ${res.statusCode}');
      }

      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as List<dynamic>);
        final len  = data.length;
        final markers = data.asMap().entries.map<Marker>((e) {
          final idx  = e.key;
          final st   = e.value;
          // DB has lat/lng columns swapped: 'longitude' field = actual lat, 'latitude' field = actual lng
          final lat = (st['longitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (st['latitude']  as num?)?.toDouble() ?? 0.0;
          debugPrint('[fetchStations] Station $idx: lat=$lat, lng=$lng (${st['libelle']})');
          return Marker(
            width: 32, height: 32,
            point: LatLng(lat, lng),
            child: Icon(
              idx == 0     ? Icons.trip_origin
                  : idx == len - 1 ? Icons.flag
                  : Icons.location_pin,
              color: idx == 0     ? Colors.green
                  : idx == len - 1 ? Colors.red
                  : Colors.orange,
              size: 28,
            ),
          );
        }).toList();

        if (mounted) {
          setState(() {
            _stations = data;
            // Pour les bus connus : toujours utiliser les marqueurs codés
            // (les coords BDD peuvent être inexactes) — comme le web utilise
            // toujours ses waypoints définis indépendamment de la BDD
            _stationMarkers = _kHardcodedWaypoints.containsKey(widget.id_b)
                ? _buildHardcodedMarkers(widget.id_b)
                : markers;
            _isLoading = false;
          });
        }

        if (len >= 2) {
          // Utiliser les waypoints définis si disponibles pour ce bus :
          // cela garantit le bon tracé indépendamment des données backend.
          final List<LatLng> waypoints;
          if (_kHardcodedWaypoints.containsKey(widget.id_b)) {
            waypoints = _kHardcodedWaypoints[widget.id_b]!;
            debugPrint('[fetchStations] Waypoints définis pour bus ${widget.id_b} : ${waypoints.length} points');
          } else {
            waypoints = data.map<LatLng>((st) {
              // DB has lat/lng columns swapped
              final lat = (st['longitude'] as num?)?.toDouble() ?? 0.0;
              final lng = (st['latitude']  as num?)?.toDouble() ?? 0.0;
              return LatLng(lat, lng);
            }).toList();
            final allValid = waypoints.every((p) =>
                _isCoordsValid(p.latitude, p.longitude) &&
                _isInTunisiaRegion(p.latitude, p.longitude));
            if (!allValid) {
              debugPrint('[fetchStations] ⚠️ Certaines stations hors Tunisie ! Vérifier la BDD.');
            }
          }
          await _loadRoute(waypoints);
        } else if (_kHardcodedWaypoints.containsKey(widget.id_b)) {
          // Backend a retourné 200 mais avec moins de 2 stations :
          // charger quand même depuis les waypoints codés
          debugPrint('[fetchStations] Seulement $len station(s) — route codée forcée pour bus ${widget.id_b}');
          await _loadRoute(_kHardcodedWaypoints[widget.id_b]!);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
        // Backend KO : charger quand même la route depuis les waypoints codés
        if (_kHardcodedWaypoints.containsKey(widget.id_b)) {
          debugPrint('[fetchStations] Backend KO — waypoints codés pour bus ${widget.id_b}');
          await _loadRoute(_kHardcodedWaypoints[widget.id_b]!);
        }
      }
    } catch (e) {
      debugPrint('[fetchStations] $e');
      if (mounted) setState(() => _isLoading = false);
      // Exception réseau : charger quand même depuis les waypoints codés
      if (_kHardcodedWaypoints.containsKey(widget.id_b)) {
        await _loadRoute(_kHardcodedWaypoints[widget.id_b]!);
      }
    }
  }

  Future<void> _fetchEta(double busLat, double busLon) async {
    if (_salarieStation == null) return;
    try {
      final uri = Uri.parse(
          '$kBackendBaseUrl/buses/${widget.id_b}/eta'
          '?stationLat=${_salarieStation!.latitude}'
          '&stationLon=${_salarieStation!.longitude}');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted && res.body.trimLeft().startsWith('{')) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          setState(() {
            _etaMinutes = data['etaMinutes'] as int?;
            _distanceKm = (data['distanceKm'] as num?)?.toDouble();
            if (_etaMinutes != null) {
              final arrival = DateTime.now().add(Duration(minutes: _etaMinutes!));
              _etaArrivalTime =
                  '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
            }
          });
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _loadRoute(List<LatLng> waypoints) async {
    if (mounted) setState(() => _routeLoading = true);
    final pts = await _fetchRoute(waypoints);
    if (!mounted) return;
    setState(() {
      _routePoints  = pts;
      _routeLoading = false;
    });

    // ── Logs de diagnostic (visibles dans flutter run / DevTools) ──
    if (pts.isNotEmpty) {
      debugPrint('[DEBUG] Nombre de points route: ${pts.length}');
      debugPrint('[DEBUG] Premier point : lat=${pts.first.latitude.toStringAsFixed(6)}, lng=${pts.first.longitude.toStringAsFixed(6)}');
      debugPrint('[DEBUG] Dernier point : lat=${pts.last.latitude.toStringAsFixed(6)},  lng=${pts.last.longitude.toStringAsFixed(6)}');
      if (pts.length > 2) {
        final mid = pts[pts.length ~/ 2];
        debugPrint('[DEBUG] Point milieu  : lat=${mid.latitude.toStringAsFixed(6)},  lng=${mid.longitude.toStringAsFixed(6)}');
      }
      final latMin = pts.map((p) => p.latitude).reduce(min);
      final latMax = pts.map((p) => p.latitude).reduce(max);
      debugPrint('[DEBUG] Plage latitude : $latMin -> $latMax'
          '${latMax > 37.0 ? "  ⚠️  DETOUR NORD DETECTE" : "  ✅ OK"}');
    }
    if (!_realGpsActive && pts.length >= 2) {
      _startSimulation();
    }
    // Toujours recentrer la carte sur la route après chargement
    if (pts.length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          final bounds = LatLngBounds.fromPoints(pts);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(48),
            ),
          );
          debugPrint('[loadRoute] Auto-fit carte sur ${pts.length} points');
        } catch (e) {
          debugPrint('[loadRoute] Auto-fit erreur: $e');
        }
      });
    }
  }

  /// Interpole lineairement N points entre chaque paire de waypoints,
  /// proportionnellement a la longueur de chaque segment.
  /// Garantit depart/arrivee exacts, simulation fluide, zero appel reseau.
  List<LatLng> _interpolateWaypoints(List<LatLng> wps,
      {int targetPoints = 150}) {
    if (wps.length < 2) return wps;
    double totalDist = 0;
    for (int i = 0; i < wps.length - 1; i++) {
      totalDist += _distanceBetween(wps[i], wps[i + 1]);
    }
    if (totalDist == 0) return wps;
    final result = <LatLng>[wps.first];
    for (int i = 0; i < wps.length - 1; i++) {
      final segDist = _distanceBetween(wps[i], wps[i + 1]);
      final steps   = max(2, (targetPoints * segDist / totalDist).round());
      for (int j = 1; j <= steps; j++) {
        final t = j / steps;
        result.add(LatLng(
          wps[i].latitude  + (wps[i + 1].latitude  - wps[i].latitude)  * t,
          wps[i].longitude + (wps[i + 1].longitude - wps[i].longitude) * t,
        ));
      }
    }
    return result;
  }

  Future<List<LatLng>> _fetchRoute(List<LatLng> waypoints) async {
    // ── Priorité 0 : route pré-calculée OSRM ─────────────────────────────────
    // Identique pixel pour pixel au tracé du web Angular.
    // Aucun appel réseau — fonctionne hors-ligne, sans CORS, sans timeout.
    if (_kPrecomputedRoutes.containsKey(widget.id_b)) {
      final pts = List<LatLng>.from(_kPrecomputedRoutes[widget.id_b]!);
      debugPrint('[Route] Bus ${widget.id_b} — ${pts.length} pts pré-calculés OSRM (= web)');
      return pts;
    }

    // Bounding box des waypoints + marge 0.15° — garde-fou anti-détour.
    final maxLat = waypoints.map((p) => p.latitude).reduce(max)  + 0.15;
    final minLat = waypoints.map((p) => p.latitude).reduce(min)  - 0.15;
    final maxLng = waypoints.map((p) => p.longitude).reduce(max) + 0.15;
    final minLng = waypoints.map((p) => p.longitude).reduce(min) - 0.15;

    bool inBounds(List<LatLng> pts) => pts.every((p) =>
        p.latitude  >= minLat && p.latitude  <= maxLat &&
        p.longitude >= minLng && p.longitude <= maxLng);

    try {
      final locations = waypoints.asMap().entries.map((e) => {
        'lat': e.value.latitude,
        'lon': e.value.longitude,
        'type': (e.key == 0 || e.key == waypoints.length - 1) ? 'break' : 'through',
      }).toList();

      final body = jsonEncode({
        'locations': locations,
        'costing': 'auto',
        'costing_options': {'auto': {'use_ferry': 0.0, 'ferry_cost': 9999}},
      });

      final res = await http
          .post(Uri.parse(_kValhallaUrl),
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final legs = data['trip']['legs'] as List;
        final all  = <LatLng>[];
        for (int i = 0; i < legs.length; i++) {
          final pts = _decodePolyline(legs[i]['shape'] as String);
          if (i > 0 && pts.isNotEmpty) pts.removeAt(0);
          all.addAll(pts);
        }
        if (all.length >= 2 && inBounds(all)) {
          debugPrint('[Valhalla] Route : ${all.length} points');
          return all;
        } else if (all.length >= 2) {
          debugPrint('[Valhalla] Détour détecté (hors bbox) — rejeté, fallback OSRM');
        }
      }
    } catch (e) {
      debugPrint('[Valhalla] Echec: $e');
    }

    // ── ② OSRM — identique au web (overview=full, geojson, radiuses=500) ──────
    try {
      final coordStr = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final radiuses = waypoints.map((_) => '500').join(';');
      final res = await http
          .get(Uri.parse('$_kOsrmUrl/$coordStr?overview=full&geometries=geojson&radiuses=$radiuses'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data   = jsonDecode(res.body) as Map<String, dynamic>;
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final pts    = coords.map<LatLng>(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        if (pts.length >= 2 && inBounds(pts)) {
          debugPrint('[OSRM] Route : ${pts.length} points');
          return pts;
        } else if (pts.length >= 2) {
          debugPrint('[OSRM] Détour détecté (hors bbox) — rejeté, fallback interpolation');
        }
      }
    } catch (e) {
      debugPrint('[OSRM] Echec: $e');
    }

    // ── ③ Fallback garanti — interpolation directe entre les waypoints ────────
    // Utilisé uniquement si Valhalla ET OSRM échouent ou retournent un détour.
    debugPrint('[Route] Fallback interpolation pour bus ${widget.id_b}');
    return _interpolateWaypoints(waypoints, targetPoints: 150);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, n = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        n |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (n & 1) != 0 ? ~(n >> 1) : (n >> 1);
      shift = 0; n = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        n |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (n & 1) != 0 ? ~(n >> 1) : (n >> 1);
      result.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return result;
  }

  void _startSimulation() {
    _stopSimulation();
    if (_routePoints.length < 2) return;

    // Déterminer la position de départ sur la route :
    // si le bus est connu mais à plus de 2 km de la route (données GPS périmées),
    // on repart depuis le début du trajet.
    LatLng startPos;
    if (_busPosition != null) {
      final nearIdx = _findNearestSegment(_busPosition!);
      final nearPt  = _routePoints[nearIdx.clamp(0, _routePoints.length - 1)];
      if (_distanceBetween(_busPosition!, nearPt) <= 2000.0) {
        _simSegIdx = nearIdx;
        startPos   = nearPt;
      } else {
        _simSegIdx = 0;
        startPos   = _routePoints[0];
      }
    } else {
      _simSegIdx = 0;
      startPos   = _routePoints[0];
    }
    _simSegT = 0.0;

    // Toujours repartir d’un tracé propre depuis la position sur la route
    if (mounted) {
      setState(() {
        _busPosition    = startPos;
        _traveledPoints = [startPos];
      });
    }

    _simLastTick = DateTime.now();
    _simTimer    = Timer.periodic(const Duration(milliseconds: 50), _simTick);
    debugPrint('[SIM] Demarrage depuis index $_simSegIdx/${_routePoints.length}');
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    _simTimer = null;    // null explicite — nécessaire pour les gardes _simTimer == null
  }

  void _simTick(Timer t) {
    if (!mounted || _realGpsActive || _routePoints.length < 2) return;

    final now  = DateTime.now();
    final dtMs = now.difference(_simLastTick!).inMilliseconds.clamp(0, 200).toDouble();
    _simLastTick = now;

    if (!_advanceSegments(dtMs)) {
      _stopSimulation();
      return;
    }

    final idx     = _simSegIdx.clamp(0, _routePoints.length - 2);
    final a       = _routePoints[idx];
    final b       = _routePoints[idx + 1];
    final lat     = a.latitude  + (b.latitude  - a.latitude)  * _simSegT;
    final lng     = a.longitude + (b.longitude - a.longitude) * _simSegT;
    final pos     = LatLng(lat, lng);
    final bearing = _calcBearing(a, b);

    if (mounted) {
      setState(() {
        _busPosition    = pos;
        _bearing        = bearing;
        _traveledPoints.add(pos);
        if (_traveledPoints.length > 500) _traveledPoints.removeAt(0);
      });
    }
    _centerIfNeeded(pos);
  }

  bool _advanceSegments(double dtMs) {
    double remaining = _kSpeedMps * dtMs / 1000.0;
    final pts = _routePoints;
    while (remaining > 0 && _simSegIdx < pts.length - 1) {
      final a      = pts[_simSegIdx];
      final b      = pts[_simSegIdx + 1];
      final segLen = _distanceBetween(a, b);
      if (segLen < 0.01) { _simSegIdx++; _simSegT = 0; continue; }
      final distToEnd = (1 - _simSegT) * segLen;
      if (remaining >= distToEnd) {
        remaining -= distToEnd;
        _simSegIdx++;
        _simSegT = 0.0;
      } else {
        _simSegT += remaining / segLen;
        remaining = 0;
      }
    }
    return _simSegIdx < pts.length - 1;
  }

  void _fastForwardSimulation(double missedMs) {
    if (_routePoints.length < 2) return;
    _advanceSegments(missedMs);

    final idx = _simSegIdx.clamp(0, _routePoints.length - 2);
    final a   = _routePoints[idx];
    final b   = _routePoints[idx + 1];
    final pos = LatLng(
      a.latitude  + (b.latitude  - a.latitude)  * _simSegT,
      a.longitude + (b.longitude - a.longitude) * _simSegT,
    );
    if (mounted) {
      setState(() {
        _busPosition = pos;
        _bearing     = _calcBearing(a, b);
        _traveledPoints.add(pos);
        if (_traveledPoints.length > 500) _traveledPoints.removeAt(0);
      });
    }
    debugPrint('[SIM] Fast-forward ${(missedMs / 1000).toStringAsFixed(1)}s'
        ' -> index $_simSegIdx/${_routePoints.length}');
  }

  int _findNearestSegment(LatLng pos) {
    double bestDist = double.infinity;
    int    bestIdx  = 0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final d = _distanceBetween(_routePoints[i], pos);
      if (d < bestDist) { bestDist = d; bestIdx = i; }
    }
    return bestIdx;
  }

  LatLng _snapToRoute(LatLng raw) {
    if (_routePoints.length < 2) return raw;
    double bestDist = double.infinity;
    LatLng bestPt   = raw;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final pt = _closestOnSegment(raw, _routePoints[i], _routePoints[i + 1]);
      final d  = _distanceBetween(raw, pt);
      if (d < bestDist) { bestDist = d; bestPt = pt; }
    }
    return bestDist <= 150 ? bestPt : raw;
  }

  LatLng _closestOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude, ay = a.latitude;
    final bx = b.longitude, by = b.latitude;
    final dx = bx - ax, dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return a;
    final t = ((p.longitude - ax) * dx + (p.latitude - ay) * dy) / lenSq;
    return LatLng(ay + t.clamp(0.0, 1.0) * dy, ax + t.clamp(0.0, 1.0) * dx);
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const R   = 6371000.0;
    final phi1    = a.latitude  * pi / 180;
    final phi2    = b.latitude  * pi / 180;
    final dPhi    = (b.latitude  - a.latitude)  * pi / 180;
    final dLambda = (b.longitude - a.longitude) * pi / 180;
    final s = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);
    return R * 2 * atan2(sqrt(s), sqrt(1 - s));
  }

  double _calcBearing(LatLng a, LatLng b) {
    final lat1 = a.latitude  * pi / 180;
    final lat2 = b.latitude  * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final x    = sin(dLng) * cos(lat2);
    final y    = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return (atan2(x, y) * 180 / pi + 360) % 360;
  }

  /// Appelé par flutter_map à chaque événement carte.
  /// Détecte les gestes utilisateur et désactive temporairement le suivi auto.
  void _onMapEvent(MapEvent event) {
    // Détecter les gestes utilisateur (drag, pinch-zoom, scroll wheel)
    if (event.source == MapEventSource.dragStart     ||
        event.source == MapEventSource.onDrag        ||
        event.source == MapEventSource.scrollWheel   ||
        event.source == MapEventSource.multiFingerGestureStart ||
        event.source == MapEventSource.onMultiFinger) {
      if (_followBus) setState(() => _followBus = false);
      // Reprendre le suivi automatiquement après 8 secondes d'inactivité
      _followBusResumeTimer?.cancel();
      _followBusResumeTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _followBus = true);
      });
    }
  }

  void _centerIfNeeded(LatLng pos) {
    if (!mounted || !_followBus) return;  // ne pas bouger si l'utilisateur navigue
    try {
      final bounds = _mapController.camera.visibleBounds;
      final ne     = bounds.northEast;
      final sw     = bounds.southWest;
      final mLat   = (ne.latitude  - sw.latitude)  * 0.3;
      final mLng   = (ne.longitude - sw.longitude) * 0.3;
      final inLat  = pos.latitude  > sw.latitude  + mLat &&
                     pos.latitude  < ne.latitude  - mLat;
      final inLng  = pos.longitude > sw.longitude + mLng &&
                     pos.longitude < ne.longitude - mLng;
      if (!inLat || !inLng) {
        _mapController.move(pos, _mapController.camera.zoom);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: 'Bus Tracking'),
      drawer: MyDrawer(
          nom: widget.nom,
          prenom: widget.prenom,
          id: widget.id,
          matricule: widget.matricule),
      body: widget.id_b == 0
          // ── Aucun bus assigné ───────────────────────────────────
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_bus_outlined,
                        size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun bus assigné',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre compte (${widget.matricule}) n\'a pas encore de bus assigné.\nContactez votre administrateur.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          // ── Carte normale ───────────────────────────────────────
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Bannière uniquement si AUCUNE position (simulation ET GPS réel)
                // Si la simulation tourne et fournit une position, ne pas afficher l'alerte
                if (_busPositionUnavailable && _busPosition == null)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    child: Row(children: [
                      const Icon(Icons.warning_amber,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Position du bus #${widget.id_b} non disponible',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 13)),
                    ]),
                  ),
                if (_etaMinutes != null)
                  Container(
                    width: double.infinity,
                    color: Colors.green.shade50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    child: Row(children: [
                      const Icon(Icons.schedule,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Arrivee dans ~$_etaMinutes min'
                        '${_distanceKm != null ? ' · ${_distanceKm!.toStringAsFixed(1)} km' : ''}',
                        style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                if (_routeLoading)
                  Container(
                    width: double.infinity,
                    color: Colors.blue.shade50,
                    padding: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 12),
                    child: const Row(children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text("Calcul de l'itineraire...",
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue)),
                    ]),
                  ),
                Expanded(
                  child: _stations.isNotEmpty
                      ? Stack(
                          children: [
                          FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            onMapEvent: _onMapEvent,
                            initialCenter: () {
                              // Priorité : premier waypoint défini (toujours correct)
                              final hw = _kHardcodedWaypoints[widget.id_b];
                              if (hw != null && hw.isNotEmpty) return hw.first;
                              // Fallback : position bus validée
                              if (_busPosition != null) return _busPosition!;
                              // Fallback : première station backend validée
                              if (_stations.isNotEmpty &&
                                  _isInTunisiaRegion(
                                    (_stations.first['longitude'] as num?)?.toDouble() ?? 0.0,
                                    (_stations.first['latitude']  as num?)?.toDouble() ?? 0.0))
                                return LatLng(
                                    (_stations.first['longitude'] as num).toDouble(),
                                    (_stations.first['latitude']  as num).toDouble());
                              return _kTunisiaCenter;
                            }(),
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(polylines: [
                                Polyline(
                                  points: _routePoints,
                                  color: const Color(0xFF1a73e8),
                                  strokeWidth: 5,
                                ),
                              ]),
                            if (_traveledPoints.length >= 2)
                              PolylineLayer(polylines: [
                                Polyline(
                                  points: _traveledPoints,
                                  color: const Color(0xFFe53935),
                                  strokeWidth: 4,
                                ),
                              ]),
                            MarkerLayer(markers: [
                              ..._stationMarkers,
                              if (_salarieStation != null)
                                Marker(
                                  width: 36, height: 36,
                                  point: _salarieStation!,
                                  child: const Icon(Icons.star,
                                      color: Colors.blue, size: 32),
                                ),
                              if (_busPosition != null)
                                Marker(
                                  width: 48, height: 48,
                                  point: _busPosition!,
                                  child: Transform.rotate(
                                    angle: _bearing * pi / 180,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 2))
                                        ],
                                      ),
                                      child: const Icon(
                                          Icons.directions_bus,
                                          color: Color(0xFF1a73e8),
                                          size: 30),
                                    ),
                                  ),
                                ),
                            ]),
                          ],
                        ),
                          // ── Bouton re-centrage (visible quand l'utilisateur a bougé la carte) ──
                          if (!_followBus)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.small(
                                heroTag: 'recenter_bus',
                                tooltip: 'Recentrer sur le bus',
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1a73e8),
                                onPressed: () {
                                  _followBusResumeTimer?.cancel();
                                  setState(() => _followBus = true);
                                  if (_busPosition != null) {
                                    _mapController.move(
                                        _busPosition!, _mapController.camera.zoom);
                                  }
                                },
                                child: const Icon(Icons.my_location),
                              ),
                            ),
                        ],
                      )
                      : const Center(
                          child:
                              Text('Aucune station disponible.')),
                ),
                // ── Panneau info bas (style panneau GPS web) ──
                if (_busPosition != null || _etaMinutes != null)
                  _buildInfoPanel(),
              ],
            ),
    );
  }

  // ── Bottom info panel (miroir du panneau GPS web) ────────────
  Widget _buildInfoPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 14, offset: Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─ En-tête bleu (= gps-panel-header web)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1a73e8),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Suivi GPS Temps Réel',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const Spacer(),
                // Point de statut animé
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _busPosition != null && !_busPositionUnavailable
                        ? const Color(0xFF00e676)
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // ─ Corps (= gps-panel-body web)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                // Infos GPS
                if (_busPosition != null) ...[
                  _infoRow('Bus ID', '${widget.id_b}'),
                  if (_kBusRouteInfo.containsKey(widget.id_b))
                    _infoRow(
                      'Ligne',
                      '${_kBusRouteInfo[widget.id_b]!["dep"]} → ${_kBusRouteInfo[widget.id_b]!["dest"]}',
                    ),
                  _infoRow('Latitude',
                      _busPosition!.latitude.toStringAsFixed(5)),
                  _infoRow('Longitude',
                      _busPosition!.longitude.toStringAsFixed(5)),
                  if (_busSpeed != null && _busSpeed! > 0)
                    _infoRow(
                        'Vitesse', '${_busSpeed!.toStringAsFixed(1)} km/h'),
                ],
                // Section ETA (= eta-panel web)
                if (_etaMinutes != null) ...[
                  const Divider(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFe8f5e9), Color(0xFFf1f8e9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFa5d6a7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // En-tête ETA
                        Row(children: [
                          const Icon(Icons.flag,
                              color: Color(0xFF2e7d32), size: 16),
                          const SizedBox(width: 6),
                          const Text('Ma station',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF2e7d32))),
                        ]),
                        const SizedBox(height: 6),
                        if (_distanceKm != null)
                          _etaRow('Distance restante',
                              '${_distanceKm!.toStringAsFixed(1)} km'),
                        _etaRow('Temps estimé', '~$_etaMinutes min'),
                        if (_etaArrivalTime != null)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Arrivée prévue',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF555555))),
                              Row(children: [
                                const Icon(Icons.access_time,
                                    size: 13, color: Color(0xFF1a73e8)),
                                const SizedBox(width: 4),
                                Text(_etaArrivalTime!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1a73e8))),
                              ]),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ligne info générique (= gps-info-row web) ─────────────────
  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF555555))),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222))),
          ],
        ),
      );

  // ── Ligne ETA (= eta-row web) ─────────────────────────────────
  Widget _etaRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF555555))),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1b5e20))),
          ],
        ),
      );
}
