<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:s1="http://microsoft.com/wsdl/types/"  
  xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"  
  xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" 
  xmlns:s="http://www.w3.org/2001/XMLSchema" 
  xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
  xmlns:tns="http://www.united-e-way.org" 
  xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" 
  xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
  version="1.0">

<xsl:template match="/">
  <!-- look for every child of schema -->
  <xsl:text>set tns </xsl:text>
  <xsl:value-of select="//wsdl:definitions/@targetNamespace"/>
  <xsl:text>
</xsl:text>
  <xsl:for-each select="//wsdl:types/s:schema/*">
    <xsl:call-template name="anyTypeTemplate" />
  </xsl:for-each>


<xsl:for-each select="//wsdl:definitions/wsdl:message">
  <xsl:call-template name="wsdlMessageTemplate" />
</xsl:for-each>


<xsl:for-each select="//wsdl:definitions/wsdl:portType">
  <xsl:call-template name="wsdlPortTypeTemplate" />
</xsl:for-each>



</xsl:template>

<xsl:template name="anyTypeTemplate">

 <xsl:for-each select="self::s:simpleType">
   <xsl:call-template name="simpleTypeTemplate"/>
 </xsl:for-each>
 <xsl:for-each select="self::s:complexType">
   <xsl:call-template name="complexTypeTemplate"/>
 </xsl:for-each>

</xsl:template>

<xsl:template name="simpleTypeTemplate">
  <xsl:if test="count(child::s:restriction/*) = 0">
    <xsl:call-template name="simpleImportType"/>
  </xsl:if>

  <!-- enumeration restrictions -->
  <xsl:for-each select="child::s:restriction[1]/child::s:enumeration[1]/parent::s:restriction[1]">
<xsl:text>
::wsdl::types::simpleType::restrictByEnumeration </xsl:text> 
  <xsl:value-of select="../@name"/>
<xsl:text> </xsl:text>
  <xsl:value-of select="@base"/>
<xsl:text> {
</xsl:text>
  <xsl:for-each select="child::s:enumeration"> 
    <xsl:call-template name="enumeration"/>
  </xsl:for-each> 

<xsl:text>
}
</xsl:text>
  </xsl:for-each>


<xsl:for-each select="child::s:restriction[1]/child::s:pattern[1]">

<xsl:text>
::wsdl::types::simpleType::restrictByPattern </xsl:text> 

<xsl:value-of select="ancestor::s:simpleType[1]/@name"/>
<xsl:text> </xsl:text>
<xsl:value-of select="ancestor::s:restriction[1]/@base"/>

<xsl:text> {</xsl:text>

<xsl:value-of select="@value" />

<xsl:text>}
</xsl:text>
</xsl:for-each>

</xsl:template>

<xsl:template name="complexTypeTemplate">


<xsl:for-each select="child::s:sequence[1]">
<xsl:text>
eval [::wsdl::elements::modelGroup::sequence::new $tns </xsl:text>
  <xsl:value-of select="../@name"/>
<xsl:text> {
</xsl:text>

<xsl:for-each select="../child::s:sequence/child::s:element" >

   <xsl:call-template name="modelSequence" />

</xsl:for-each>

     <xsl:text>}]
</xsl:text>
</xsl:for-each>

</xsl:template>


<xsl:template name="enumeration">
     <xsl:text> </xsl:text>
<xsl:text>&quot;</xsl:text>
 <xsl:value-of select="@value"/>
<xsl:text>&quot; </xsl:text>
</xsl:template>

<xsl:template name="simpleImportType">

  <xsl:text>::wsdl::types::simpleType::new $tns </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> </xsl:text>
  <xsl:value-of select="s:restriction/@base" />
  <xsl:text>
</xsl:text>
</xsl:template>

<xsl:template name="modelSequence">
   <xsl:text>  {</xsl:text>
<xsl:text>&quot;</xsl:text>
 <xsl:value-of select="@name"/>
<xsl:text>&quot; </xsl:text>

<xsl:text> &quot;</xsl:text>
 <xsl:value-of select="@type"/>
<xsl:text>&quot;</xsl:text>

<xsl:text> &quot;</xsl:text>
 <xsl:value-of select="@minOccurs"/>
<xsl:text>&quot; </xsl:text>

<xsl:text> &quot;</xsl:text>
 <xsl:value-of select="@maxOccurs"/>
<xsl:text>&quot; </xsl:text>

     <xsl:text>}
</xsl:text>
</xsl:template>

<!-- handle WSDL:message -->


<xsl:template name="wsdlMessageTemplate">
  <xsl:text>eval [::wsdl::messages::new $tns </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> </xsl:text>
  <xsl:value-of select="wsdl:part/@element"/>
  <xsl:text>] 
</xsl:text>
</xsl:template>

<!-- Handle portTypes -->


<xsl:template name="wsdlPortTypeTemplate">
  <xsl:for-each select="wsdl:operation">
    <xsl:call-template name="wsdlOperationTemplate"/>
  </xsl:for-each>
  <xsl:text>::wsdl::portTypes::new $tns </xsl:text>
  <xsl:value-of select="@name"/>
  <xsl:text> {</xsl:text>
  <xsl:for-each select="wsdl:operation">
    <xsl:value-of select="@name"/>
    <xsl:text> </xsl:text>
  </xsl:for-each>
  <xsl:text>}
</xsl:text>

</xsl:template>

<xsl:template name="wsdlOperationTemplate">
  <xsl:text>eval [::wsdl::operations::new $tns </xsl:text>
  <xsl:value-of select="@name"/> 
  <xsl:for-each select="child::*">
    <xsl:call-template name="operationIOTemplate"/>
  </xsl:for-each>
  <xsl:text>]
</xsl:text>
</xsl:template>

<xsl:template name="operationIOTemplate">
  <xsl:text> {</xsl:text>
  <xsl:value-of select="name()"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="@message"/>
  <xsl:text>}</xsl:text>
</xsl:template>

</xsl:stylesheet> 
