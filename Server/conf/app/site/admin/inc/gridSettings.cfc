<cfcomponent output="false">
	<cfset variables.fileName = "NA">
	<cfset variables.fileExist = false>

    <cffunction name="init" output="false">
    	<!---
        <cfargument name="SCRIPTNAME" required="true">
        <cfset variables.fileName = arguments.SCRIPTNAME>
        --->
        <cfreturn this>
    </cffunction>
	
	<cffunction name="getFileName" access="public" returntype="any">
		<cfargument name="SCRIPTNAME" required="true">
		<cfset variables.fileName = "#GetFileFromPath(arguments.SCRIPTNAME)#.xml">
		<cfset xmlFileDir = "#ExpandPath(".")#/settings/#variables.fileName#">
		<cfif FileExists(xmlFileDir)>
		
		<cfelse>	
			
		</cfif>
	</cffunction>
	
	<cffunction name="queryForFileName" access="public" returntype="any">
		<cfif variables.fileName EQ "xx_client_groups.cfm">
			<!--- Client Groups Grid --->
			<cfquery name="qData" datasource="#mpDBSource#">
		    	SELECT	cci.*, av.defs_date
		        <cfif hasHWData EQ true>
		        	, hw.mpa_Model_Name, hw.mpa_Model_Identifier
		        </cfif>
		        FROM	mp_clients_view cci
		        LEFT 	JOIN AV_INFO av 
		        ON cci.cuuid = av.cuuid
		        <cfif hasHWData EQ true>
		        	LEFT JOIN mpi_SPHardwareOverview hw ON
		        	cci.cuuid = hw.cuuid
		        </cfif>
			</cfquery>
			<cfreturn qData.ColumnList>
		</cfif>
		
		<cfreturn>
	</cffunction>
	
	<cffunction name="genJSFromXML" access="public" returntype="any">
		<cfargument name="xmlData" required="yes">
		
		<cfset settings = structNew()>
		<cfif not structKeyExists(xml,"settings")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		
		<cfloop item="key" collection="#xml.settings#">
		   <cfif len(trim(xml.settings[key].xmlText))>
		      <cfset settings[key] = xml.settings[key].xmlText>
		   </cfif>
		</cfloop>
		
		<cfset settings.columns = structNew()>
		<cfif not structKeyExists(xml.settings,"columns") or not structKeyExists(xml.settings.columns,"column")>
		   <cfthrow message="Invalid settings XML file!">
		</cfif>
		<cfset columnsArray = ArrayNew(1)>
		<cfset columnsArray = #xml.settings.columns#>
		
		
		<cfloop item="key" collection="#xml.settings.columns.column#">
		   <cfif len(trim(xml.settings.email.emailaddresses[key].xmlText))>
		      <cfset application.settings.emailaddresses[key] = xml.settings.email.emailaddresses[key].xmlText>
		   </cfif>
		</cfloop>

	
	</cffunction>
	
	<cffunction name="genColModelForTable" access="public" returntype="any">
		<cfargument name="cols" required="yes">
		<cfargument name="forFile" required="yes">
		
		<cfset var i = 2>
		<cfxml variable="MyDoc">
		<?xml version='1.0' encoding='utf-8' ?>
		<settings>
		   <columns>
		   <cfloop array="#arguments.cols#" index="item">
			<column>
				<order><cfif #item# EQ "cuuid">1<cfelse><cfoutput>#i#</cfoutput></cfif></order>
				<name><cfoutput>#item#</cfoutput></name>
				<dname><cfoutput>#item#</cfoutput></dname>
				<width>100</width>
				<align>left</align>
				<hidden>false</hidden>
			</column><cfset i = i + 1>
			</cfloop>
		   </columns>
		</settings>
		</cfxml>
		<cfreturn MyDoc>
	</cffunction>
	
	<cffunction name="sortArrayOfStructs" returntype="array" access="public">
		<cfargument name="arrayOfStructs" type="array" required="yes" />
		<cfargument name="structKey" type="String" required="yes" />
		<cfargument name="sortOrder" type="string" required="no" default="asc" />
		<cfargument name="sortType" type="string" required="no" default="textnocase" />	
		
		<cfset var delim = ".">
		<cfset var sortArray = arraynew(1)>
		<cfset var returnArray = arraynew(1)>
		<cfset var count = arrayLen(arguments.arrayOfStructs)>
		<cfset var ii = 1>
		<!--- loop over the array of structs, building the sortArray --->
		<cfloop from="1" to="count" index="x">
			<cfset sortArray[x] = arguments.arrayOfStructs[x][arguments.structKey] & delim & x>
		</cfloop>
		<!--- sort the array --->
		<cfset _arrsort = arraySort(sortArray,arguments.sortType,arguments.sortOrder)>
		<!--- build the return array --->
		<cfloop from="1" to="count" index="x">
			<cfset returnArray[x] = arguments.arrayOfStructs[listLast(sortArray[x],delim)]>
		</cfloop>
        
		<cfreturn returnArray>
	</cffunction>
	
	<cfscript>
		/**
		 * Sorts an array of structures based on a key in the structures.
		 * 
		 * @param aofS      Array of structures. 
		 * @param key      Key to sort by. 
		 * @param sortOrder      Order to sort by, asc or desc. 
		 * @param sortType      Text, textnocase, or numeric. 
		 * @param delim      Delimiter used for temporary data storage. Must not exist in data. Defaults to a period. 
		 * @return Returns a sorted array. 
		 * @author Nathan Dintenfass (nathan@changemedia.com) 
		 * @version 1, December 10, 2001 
		 */
		function arrayOfStructsSort(aOfS,key){
				//by default we'll use an ascending sort
				var sortOrder = "asc";        
				//by default, we'll use a textnocase sort
				var sortType = "textnocase";
				//by default, use ascii character 30 as the delim
				var delim = ".";
				//make an array to hold the sort stuff
				var sortArray = arraynew(1);
				//make an array to return
				var returnArray = arraynew(1);
				//grab the number of elements in the array (used in the loops)
				var count = arrayLen(aOfS);
				//make a variable to use in the loop
				var ii = 1;
				//if there is a 3rd argument, set the sortOrder
				if(arraylen(arguments) GT 2)
					sortOrder = arguments[3];
				//if there is a 4th argument, set the sortType
				if(arraylen(arguments) GT 3)
					sortType = arguments[4];
				//if there is a 5th argument, set the delim
				if(arraylen(arguments) GT 4)
					delim = arguments[5];
				//loop over the array of structs, building the sortArray
				for(ii = 1; ii lte count; ii = ii + 1)
					sortArray[ii] = aOfS[ii][key] & delim & ii;
				//now sort the array
				arraySort(sortArray,sortType,sortOrder);
				//now build the return array
				for(ii = 1; ii lte count; ii = ii + 1)
					returnArray[ii] = aOfS[listLast(sortArray[ii],delim)];
				//return the array
				return returnArray;
		}
	</cfscript>
	
	<cffunction name="ConvertXmlToStruct" access="public" returntype="struct" output="false">
		<cfargument name="xmlNode" type="string" required="true" />
		<cfargument name="str" type="struct" required="true" />
		<!---Setup local variables for recurse: --->
		<cfset var i = 0 />
		<cfset var axml = arguments.xmlNode />
		<cfset var astr = arguments.str />
		<cfset var n = "" />
		<cfset var tmpContainer = "" />
		
		<cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
		<cfset axml = axml[1] />
		<!--- For each children of context node: --->
		<cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
			<!--- Read XML node name without namespace: --->
			<cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
			<!--- If key with that name exists within output struct ... --->
			<cfif structKeyExists(astr, n)>
				<!--- ... and is not an array... --->
				<cfif not isArray(astr[n])>
					<!--- ... get this item into temp variable, ... --->
					<cfset tmpContainer = astr[n] />
					<!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
					<cfset astr[n] = arrayNew(1) />
					<!--- ... and reassing temp item as a first element of new array: --->
					<cfset astr[n][1] = tmpContainer />
				<cfelse>
					<!--- Item is already an array: --->
					
				</cfif>
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
						<!--- recurse call: get complex item: --->
						<cfset astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
					<cfelse>
						<!--- else: assign node value as last element of array: --->
						<cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
				</cfif>
			<cfelse>
				<!---
					This is not a struct. This may be first tag with some name.
					This may also be one and only tag with this name.
				--->
				<!---
						If context child node has child nodes (which means it will be complex type): --->
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
					<!--- recurse call: get complex item: --->
					<cfset astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
				<cfelse>
					<!--- else: assign node value as last element of array: --->
					<!--- if there are any attributes on this element--->
					<cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
						<!--- assign the text --->
						<cfset astr[n] = axml.XmlChildren[i].XmlText />
							<!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
						 <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
						 <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
							 <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
								 <!--- remove any namespace attributes--->
								<cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
							 </cfif>
						 </cfloop>
						 <!--- if there are any atributes left, append them to the response--->
						 <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
							 <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
						</cfif>
					<cfelse>
						 <cfset astr[n] = axml.XmlChildren[i].XmlText />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- return struct: --->
		<cfreturn astr />
	</cffunction>
	
</cfcomponent>	