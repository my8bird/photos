require(['dojo/query', 'dojo/dom', 'dijit/TooltipDialog', 'dojo/domReady!'], function(query, dom, dialog) {
   function toggleUploadMenu() {
      var d = new dialog();
console.log(d.show)
      d.show();
   }

   query('#upload').on('click', toggleUploadMenu);
});

