---
layout: default
title: MacPatch
slug: home
base_url: "./"
---

<div class="container-full" id="content">

  <!-- Jumbotron -->
  <div class="jumbotron">
    <div class="row">
      <div class="col-sm-12 jumbotron-head shadow">
        <h1>MacPatch</h1>
        <p class="lead">An open source management suite for large Mac OS X environments.</p>
        <p><a class="btn btn-main btn-lg btn-success" href="https://github.com/SMSG-MAC-DEV/MacPatch" role="button"><i class="fa fa-github fa-lg"></i> MacPatch on GitHub</a></p>
        <!-- Social Buttons -->
          <a class="btn btn-link underline-off" href="https://twitter.com/share?text=MacPatch+-+The+open+source+Mac+OS+X+management+suite&url=http%3A%2F%2Fmacpatch.github.io" onclick="return popup('https://twitter.com/share?text=MacPatch+-+The+open+source+Mac+OS+X+management+suite&url=http%3A%2F%2Fmacpatch.github.io')"><i class="fa fa-twitter"></i> Tweet</a>
          <a class="btn btn-link underline-off" href="https://twitter.com/intent/user?screen_name=macpatchsw" onclick="return popitup('https://twitter.com/intent/user?screen_name=macpatchsw')"><i class="fa fa-twitter"></i> Follow</a>
          <!-- /Social Buttons -->
      </div>
      <div class="row centered">
        <div class="col-sm-2" style="text-align: right">
          <!-- left col -->
        </div>
        <div class="col-sm-8">
          <img src="{{ page.base_url }}images/selfpatch.png" alt="MacPatch" class="center-block" style="vertical-align:bottom;">
        </div>
        <div class="col-sm-2" style="text-align: left">
          <!-- right col -->
        </div>
      </div>
    </div>
  </div> <!-- /jumbotron -->

  <div class="full-block shadow">
    <div class="row">
      <div class="col-sm-8 col-sm-offset-2">
        <div class="row">
          <div class="col-sm-4">
          	<h3><span class="glyphicon glyphicon-download"></span> Patch Management</h3>
            <p>Deploy Apple and third party patch content.</p>
          </div>
          <div class="col-sm-4">
            <h3><span class="glyphicon glyphicon-stats"></span> Inventory</h3>
            <p>Collect inventory data such as admin accounts, installed apps, FileVault status, and more. </p>
         </div>
          <div class="col-sm-4">
            <h3><span class="glyphicon glyphicon-book"></span> Software Catalog</h3>
            <p>Users can self install software from your list of approved packages. No admin required.</p>
          </div>
        </div>
        <!-- second row -->
        <div class="row">
          <div class="col-sm-4">
            <h3><span class="glyphicon glyphicon-fullscreen"></span> Scalable</h3>
            <p>Easily deploy additional servers as the size of your deployment grows.</p>
          </div>
          <div class="col-sm-4">
            <h3><span class="glyphicon glyphicon-tasks"></span> Configurable</h3>
            <p>Settings such as scanning and patching schedules can be customized.</p>
         </div>
          <div class="col-sm-4">
            <h3><span class="glyphicon glyphicon-share"></span> Open Source</h3>
            <p>The entire code is available on GitHub.</p>
          </div>
        </div>
      </div>
    </div>
  </div> <!-- /full-block -->

  <div class="container">
    <div class="row text-center" style="padding-top: 80px">
      <div class="col-sm-4">
        <img src="{{ page.base_url }}images/swcatalog.png" alt="MacPatch" class="center-block">
        <h3>Software Catalog</h3>
        <p>End users can install software from a catalog that you manage. No admin required. Create multiple catalogs for different sets of users.</p>
      </div>
      <div class="col-sm-4">
        <img src="{{ page.base_url }}images/patchgroup.png" alt="MacPatch" class="center-block">
        <h3>Patch Groups</h3>
        <p>You can create multiple patch groups. Each patch group can be configured with a different baseline. For example create one patch group for your servers and one for desktops.</p>
      </div>
      <div class="col-sm-4">
        <img src="{{ page.base_url }}images/terminal.png" alt="MacPatch" class="center-block">
        <h3>Terminal</h3>
        <p>Most features can be accessed from the command line for remote administrating and scripting.</p>
      </div>
    </div>
  </div>


    <div class="container textblock">
      <div class="row">
        <div class="col-sm-10 col-sm-offset-1">
          <!-- Text block -->
      </div>
    </div>
  </div> <!-- /container textblock -->

</div> <!-- /container content -->
