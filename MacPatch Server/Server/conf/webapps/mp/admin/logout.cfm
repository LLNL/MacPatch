<cfinclude template="../assets/_secure_header.cfm">

<div class="row">

	<div class="span2">
		<h2>Log Out</h2>
	</div>

	<div class="span14">

		<div class="actions">
			<p>
				Are you sure you wish to logout?
			</p>

			<a class="btn" href="../">Yes, log me out</a>
		</div>


		<div class="alert-message block-message success">
			<p><strong>CFML Bootstrap Help</strong> Clicking this button will take you to a page on the outside of this directory.  There the <code>Application.cfc</code>
			will simply delete the necessary keys from the <code>session</code> scope making sure you can't get back in again.</p>
		</div>

	</div>

</div>

<cfinclude template="../assets/_secure_footer.cfm">