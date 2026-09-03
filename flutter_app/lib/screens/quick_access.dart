import 'package:flutter/material.dart';
import '../data/settings.dart';
import '../theme/tokens.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({super.key});
  @override
  State<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends State<QuickAccessScreen> {
  late String shape, color, corner;
  late List<String> slots;
  @override
  void initState() {
    super.initState();
    final s = Settings.instance;
    shape = s.navShape; color = s.navColor; corner = s.navCorner; slots = [...s.navSlots];
  }
  static const features = <Map<String, String>>[
    {'id':'connect','label':'Connect','img':'https://media.nowssb.com/migrated-images/ea559460014dd8d9_file_00000000b84c7209ab496862cacd6a7f_kagsie.png'},
    {'id':'practice','label':'Practice','img':'https://media.nowssb.com/migrated-images/44ed38a222535b9c_38538b80-56d8-11f1-8fad-095787cce754_xam2bb.png'},
    {'id':'library','label':'Library','img':'https://media.nowssb.com/migrated-images/62e5d0908e54a2a6_c500a990-56cf-11f1-8fad-095787cce754_1_zqzbal.png'},
    {'id':'store','label':'Store','img':'https://media.nowssb.com/migrated-images/86a1283688196499_ce4eb640-56cf-11f1-8fad-095787cce754_wf294m.png'},
    {'id':'profile','label':'Profile','img':'https://media.nowssb.com/migrated-images/3979b9fa35b579e6_62ebfdb0-56d2-11f1-8fad-095787cce754_oap0j4.png'},
    {'id':'progress','label':'Progress','img':'https://media.nowssb.com/migrated-images/0480c10b8a8d79dd_file_00000000ae607208aa51504989648920_ml2czc.png'},
    {'id':'wordscience','label':'Word Sci','img':'https://media.nowssb.com/migrated-images/dd44cf9fc35b783c_file_0000000086d872089ce376674620d5f3_mtfftb.png'},
    {'id':'meaningstore','label':'Meaning','img':'https://media.nowssb.com/migrated-images/1a5f669e63dbae9d_file_00000000854881fa9a548a68fae59c15_w1utya.png'},
    {'id':'search','label':'Search','img':'https://media.nowssb.com/migrated-images/8d85320f63c3e176_file_00000000029c7208b5e915d9af2c480c_tuccwo.png'},
    {'id':'cart','label':'Cart','img':'https://media.nowssb.com/migrated-images/311c26afee2bc52c_file_00000000f02c72088cd128f3f4b08af5_vskoom.png'},
    {'id':'wishlist','label':'Wishlist','img':'https://media.nowssb.com/migrated-images/a74a9935fb237eb8_file_0000000055d8720895f7ba98c4a7bf4a_s2lzab.png'},
    {'id':'routines','label':'Routines','img':'https://media.nowssb.com/migrated-images/307233cd22669455_file_00000000f740820ba6aaa761133e8889_fitm0p.png'},
    {'id':'chat','label':'Chat','img':'https://media.nowssb.com/migrated-images/db15f3026ea179dc_1ae1b990-5bf2-11f1-8248-b91d5cd919c2_z3xi3j.png'},
    {'id':'ai','label':'AI Rx','img':'https://media.nowssb.com/migrated-images/41c9ed21b2822c90_file_0000000062a882089abd27eb90ea3945_ngqyu6.png'},
    {'id':'streak','label':'Streak','img':'https://media.nowssb.com/migrated-images/f82047a0e727766b_file_0000000010fc820891f9e15a38316d2b_ffffhq.png'},
    {'id':'settings','label':'Settings','img':'https://media.nowssb.com/migrated-images/523b5889d13cb14a_260480b0-56d8-11f1-8fad-095787cce754_rz6zbi.png'},
    {'id':'everything','label':'Everything','img':'https://media.nowssb.com/migrated-images/47f9e2c9fad5a78f_file_00000000be547207aaa56f43cfef4f67_nxhvw0.png'},
  ];
  Map<String,String> getById(String id) => features.firstWhere((x)=>x['id']==id, orElse:()=>features.first);
  void toggle(String id) { setState(() { final i=slots.indexOf(id); if(i>=0){if(slots.length>1)slots.removeAt(i);} else {if(slots.length>=5)slots.removeAt(0); slots.add(id);} }); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NwsbColors.deep,
    appBar: AppBar(backgroundColor: NwsbColors.deep, foregroundColor: Colors.white, title: const Text('Quick Access'), actions:[TextButton(onPressed:()=>setState((){shape='default';color='glass';corner='rounded';slots=['connect','practice','library','store','profile'];}),child:const Text('Reset',style:TextStyle(color:NwsbColors.goldLight)))]),
    body: ListView(padding:const EdgeInsets.fromLTRB(20,12,20,120),children:[
      const Text('CUSTOMIZE YOUR NAVIGATION',style:TextStyle(color:NwsbColors.mist,letterSpacing:2.5,fontSize:10,fontWeight:FontWeight.w700)),
      const SizedBox(height:8), const Text('Reshape your bottom navigation bar',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w700)),
      const SizedBox(height:6), const Text('Pick its shape, colour and the exact feature icons it shows.',style:TextStyle(color:Colors.white60,fontSize:13,height:1.5)),
      const SizedBox(height:20), _section('Preview'), _preview(),
      _section('Shape'), _options({'default':'Default','pill':'Floating Pill','rect':'Floating Rectangle'},shape,(v)=>setState(()=>shape=v)),
      if(shape=='rect') _options({'rounded':'Rounded Corners','edge':'Edge Corners'},corner,(v)=>setState(()=>corner=v)),
      _section('Colour'), _options({'glass':'Default Glass','black':'Black'},color,(v)=>setState(()=>color=v)),
      _section('Nav Bar Icons · ${slots.length} / 5'), const Text('Pick up to 5 features. Tap any tile to add or remove it. Selected ones show in your nav in order; tapping a 6th replaces the oldest.',style:TextStyle(color:Colors.white54,fontSize:11,height:1.5)),
      const SizedBox(height:14), Text('IN YOUR NAV · ${slots.length} / 5',style:const TextStyle(color:NwsbColors.mist,letterSpacing:1.5,fontSize:10,fontWeight:FontWeight.w700)), _grid(slots), const SizedBox(height:18), const Text('AVAILABLE FEATURES',style:TextStyle(color:NwsbColors.mist,letterSpacing:1.5,fontSize:10,fontWeight:FontWeight.w700)), _grid(features.map((f)=>f['id']!).where((id)=>!slots.contains(id)).toList()),
      const SizedBox(height:24), SizedBox(height:52,child:ElevatedButton.icon(onPressed:() async {await Settings.instance.setNavConfig(shape:shape,color:color,corner:corner,slots:slots);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Applied to your nav ✓')));},icon:const Icon(Icons.check),label:const Text('Apply Changes'),style:ElevatedButton.styleFrom(backgroundColor:NwsbColors.goldLight,foregroundColor:NwsbColors.deep,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))))),
    ]),
  );
  Widget _section(String t)=>Padding(padding:const EdgeInsets.only(top:22,bottom:10),child:Text(t.toUpperCase(),style:const TextStyle(color:NwsbColors.goldLight,letterSpacing:2,fontSize:10,fontWeight:FontWeight.w700)));
  Widget _options(Map<String,String> values,String selected,ValueChanged<String> onTap)=>Wrap(spacing:8,runSpacing:8,children:values.entries.map((e)=>ChoiceChip(label:Text(e.value),selected:e.key==selected,onSelected:(_)=>onTap(e.key),selectedColor:NwsbColors.goldLight,backgroundColor:const Color(0x14FFFFFF),labelStyle:TextStyle(color:e.key==selected?NwsbColors.deep:Colors.white70,fontSize:11),side:const BorderSide(color:Color(0x24FFFFFF)))).toList());
  Widget _preview(){final radius=shape=='pill'?40.0:shape=='rect'?(corner=='rounded'?20.0:2.0):28.0;final bg=color=='black'?Colors.black:const Color(0xDD182033);return Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:const Color(0x0DFFFFFF),borderRadius:BorderRadius.circular(16)),child:Container(height:82,padding:const EdgeInsets.symmetric(horizontal:8),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(radius),border:Border.all(color:const Color(0x33FFFFFF))),child:Row(children:[for(final id in slots)Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[_icon(getById(id)['img']!,28),const SizedBox(height:4),Text(getById(id)['label']!,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,fontSize:9))]))])));}
  Widget _grid(List<String> ids)=>GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,mainAxisSpacing:9,crossAxisSpacing:9,childAspectRatio:1.05,children:[for(final id in ids){final f=getById(id);final selected=slots.contains(id);GestureDetector(onTap:()=>toggle(id),child:Container(decoration:BoxDecoration(color:selected?const Color(0x1AE8D5A3):const Color(0x0DFFFFFF),borderRadius:BorderRadius.circular(16),border:Border.all(color:selected?const Color(0x66E8D5A3):const Color(0x24FFFFFF))),child:Stack(children:[Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[_icon(f['img']!,30),const SizedBox(height:5),Text(f['label']!,style:TextStyle(color:selected?NwsbColors.goldLight:Colors.white70,fontSize:10,fontWeight:selected?FontWeight.w700:FontWeight.w400))])),if(selected)Positioned(top:6,right:7,child:Text('${slots.indexOf(id)+1}',style:const TextStyle(color:NwsbColors.goldLight,fontSize:11,fontWeight:FontWeight.w800)))]))}]);
  Widget _icon(String url,double size)=>Image.network(url,width:size,height:size,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.circle_outlined,size:size,color:Colors.white54));
}
