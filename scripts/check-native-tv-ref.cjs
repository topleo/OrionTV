// Raw native hosts intentionally have no requestTVFocus method, like Paper hosts.
const fs = require('fs'), path = require('path'), assert = require('assert');
const ts = require('typescript'), React = require('react'), renderer = require('react-test-renderer');
const { act } = renderer;
const sent = [];
const source = fs.readFileSync(path.join(__dirname, '../components/navigation/NativeTVControls.tsx'), 'utf8');
const compiled = ts.transpileModule(source, { compilerOptions: { jsx: ts.JsxEmit.React, module: ts.ModuleKind.CommonJS, esModuleInterop: true } }).outputText;
const mod = { exports: {} };
const mocks = id => {
  if (id === 'react-native') return {
    View: 'View',
    requireNativeComponent: name => name,
    findNodeHandle: view => view._nativeTag,
    UIManager: {
      getViewManagerConfig: () => ({ Commands: { requestTVFocus: 0 } }),
      dispatchViewManagerCommand: (tag, command, args) => sent.push({ tag, command, args }),
    },
  };
  if (id === '@/constants/TVTheme') return { isAppleTV: true };
  return require(id);
};
new Function('require', 'module', 'exports', compiled)(mocks, mod, mod.exports);
for (const [index, Control] of [mod.exports.NativeTVTabBar, mod.exports.NativeTVMenu].entries()) {
  let handle, tree;
  act(() => { tree = renderer.create(React.createElement(Control, { ref: view => { handle = view; } }), {
    createNodeMock: () => ({ _nativeTag: 101 + index }),
  }); });
  assert.equal(typeof handle.requestTVFocus, 'function');
  assert.doesNotThrow(() => handle.requestTVFocus());
  assert.deepEqual(sent[index], { tag: 101 + index, command: 0, args: [] });
  act(() => tree.unmount());
  assert.equal(handle, null, 'unmounted controls must clear their focus refs');
}
console.log('Raw UIKit refs support focus commands, including command index zero, and clear on unmount');
