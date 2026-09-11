set -e
cd "$(dirname "$0")"
python -u export.py
python -u docs_build.py
python -u sequences.py
cd ../../../docs
rm -f ilha-digital-godot-kit.zip
python -c "import shutil; shutil.make_archive('ilha-digital-godot-kit','zip','.','ilha-digital-godot-kit'); print('zip ok')"
echo KIT_DONE
