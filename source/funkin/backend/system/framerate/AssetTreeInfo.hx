package funkin.backend.system.framerate;

import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.IModsAssetLibrary;
import funkin.backend.assets.ScriptedAssetLibrary;

class AssetTreeInfo extends FramerateCategory {
	public function new() {
		super("Asset Libraries Tree Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		var text = 'Not initialized yet\n';
		if (Paths.assetsTree != null){
			text = "";
			for(l in Paths.assetsTree.libraries) {
				var l = AssetsLibraryList.getCleanLibrary(l);

				var tag = l.tag.toString().toUpperCase();

				if (l is ScriptedAssetLibrary)
					text += '${Type.getClassName(Type.getClass(l))} - $tag - ${cast(l, ScriptedAssetLibrary).scriptName} (${cast(l, ScriptedAssetLibrary).modName} | ${cast(l, ScriptedAssetLibrary).libName} | ${cast(l, ScriptedAssetLibrary).prefix})\n';
				else if (l is IModsAssetLibrary)
					text += '${Type.getClassName(Type.getClass(l))} - $tag - ${cast(l, IModsAssetLibrary).modName} - ${cast(l, IModsAssetLibrary).libName} (${cast(l, IModsAssetLibrary).prefix})\n';
				else
					text += Std.string(l) + ' - $tag\n';
			}
		}
		if (text != "")
			text = text.substr(0, text.length-1);

		this.text.text = text;
		super.__enterFrame(t);
	}
}