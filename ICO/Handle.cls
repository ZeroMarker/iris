Class ICO.Handler Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

Parameter CONTENTTYPE = "application/json";

Parameter CONVERTINPUTSTREAM = 1;

Parameter CHARSET = "utf-8";

Parameter MAXAGE = 5;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/inventory/listbeans" Method="GET" Call="ListRawBeans" />
  <Route Url="/inventory/getbeans/:id/:quantity" Method="POST" Call="GetRawBeans" />
  <Route Url="/catalog/catalogproduct" Method="POST" Call="CatalogProduct" />
  <Route Url="/catalog/getproducts" Method="GET" Call="GetProducts" />
  <Route Url="/catalog/getproducts/:fresh" Method="GET" Call="GetProducts" />
  <Route Url="/catalog/sellproduct/:id/:quantity" Method="POST" Call="SellProduct" />
</Routes>
}

ClassMethod SellProduct(id As %String, quantity As %Numeric) As %Status
{
  Try {
    If (1 '= ##class(ICO.catalog).%ExistsId(id)) {
      Set err = {}
      Set err."error" = "Catalog ID "_id_" does NOT exist!"
      Write err.%ToJSON()
    }
    Else {
      Set item = ##class(ICO.catalog).%OpenId(id)
      If (quantity > item.quantity) {
        Set err = {}
        Set err."error" = "You tried to get "_quantity_" bags, but we only have "_item.quantity_" available."
        Write err.%ToJSON()
      }
      Else {
        Set item.quantity = (item.quantity - quantity)
        Do item.%JSONExportToString(.outstring)
        Write outstring
        Set sc = item.%Save()
      }
    }
  }
  Catch (oException) {
    Set expobj = {}
    Set expobj."exception" = oException.%AsSystemError()
    Write expobj.%ToJSON()
  }
  Quit $$$OK
}

ClassMethod GetProducts(fresh As %Boolean = 1) As %Status
{
  Try {
    Set sqlquery = "SELECT catalog_id, product_code, quantity, price, time_roasted, roasting_notes, img FROM ICO.catalog"
    If fresh = 1 {
      Set sqlquery = sqlquery_" WHERE time_roasted > DATEADD('day',-?,CURRENT_DATE)"
    }
    Else {
      Set sqlquery = sqlquery_" WHERE time_roasted <= DATEADD('day',-?,CURRENT_DATE)"
    }
    Set rs = ##class(%SQL.Statement).%ExecDirect(,sqlquery, ..#MAXAGE)
    Set itemsarray = []

    While rs.%Next() {
      Do itemsarray.%Push( {
                  "catalog_id": (rs.%Get("catalog_id")),
                  "product_code": (rs.%Get("product_code")),
                  "quantity": (rs.%Get("quantity")),
                  "time_roasted": (rs.%Get("time_roasted")),
                  "roasting_notes": (rs.%Get("roasting_notes")),
                  "img": (rs.%Get("img")),
                  "price": (rs.%Get("price"))
      }
      )
    }
    Set itemsobj = {}
    Set itemsobj."rowcount" = rs.%ROWCOUNT
    Set itemsobj."products" = itemsarray
    Write itemsobj.%ToJSON()
  }
  Catch (oException) {
    Set expobj = {}
    Set expobj."exception" = oException
    Write expobj.%ToJSON()
  }
  Quit $$$OK
}

ClassMethod GetJSONFromRequest(Output obj As %DynamicObject) As %Boolean
{
  Set ok = 1
  Try {
    Set obj = ##class(%DynamicObject).%FromJSON(%request.Content)
  }
  Catch ex {
    Set ok = 0
  }
  Quit ok
}

ClassMethod CatalogProduct() As %Status
{
  If '..GetJSONFromRequest(.obj) {
    Set %response.Status = ..#HTTP400BADREQUEST
    Set error = { "error": "No JSON body in request" }
    Write error.%ToJSON()
    Quit $$$OK
  }

  Try {
    Set catobj = ##class(ICO.catalog).%New()
    Set catobj.productcode = obj."product_code"
    Set catobj.quantity = obj."quantity"
    Set catobj.price = obj."price"
    Set catobj.timeroasted = obj."time_roasted"
    Set catobj.roastingnotes = obj."roasting_notes"
    Set catobj.img = obj."img"
    Set sc = catobj.%Save()
    Set resp = {}
    Set resp."success" = 1
    Write resp.%ToJSON()
  }
  Catch (oException) {
    Set expobj = {}
    Set expobj."exception" = oException.%AsSystemError()
    Set %response.Status = ..#HTTP400BADREQUEST
    Write expobj.%ToJSON()
  }
  Quit $$$OK
}

ClassMethod GetRawBeans(id As %String, quantity As %Numeric) As %Status
{
  Try {
    If (1 '= ##class(ICO.inventory).%ExistsId(id)) {
      Set err = {}
      Set err."error" = "ID "_id_" does NOT exist!"
      Write err.%ToJSON()
    }
    Else {
      Set item = ##class(ICO.inventory).%OpenId(id)
      If (quantity > item.quantitykg) {
        Set err = {}
        Set err."error" = "You tried to get "_quantity_", but we only have "_item.quantitykg_" kilograms available."
        Write err.%ToJSON()
      }
      Else {
        Set item.quantitykg = (item.quantitykg - quantity)
        Set sc = item.%Save()
        Do item.%JSONExportToString(.outstring)
        Write outstring
      }
    }
  }
  Catch (oException) {
    Set expobj = {}
    Set expobj."exception" = oException.%AsSystemError()
    Write expobj.%ToJSON()
  }
  Quit $$$OK
}

ClassMethod ListRawBeans() As %Status
{
  Try {
    Set sqlquery = "SELECT ID, vendor_product_code, date_arrival, SUM(quantity_kg) AS quantity_kg FROM ICO.inventory GROUP BY vendor_product_code ORDER BY date_arrival"
    Set rs = ##class(%SQL.Statement).%ExecDirect(,sqlquery)
    Set itemsarray = []

    While rs.%Next() {
      Do itemsarray.%Push({
                    "id": (rs.%Get("ID")),
                    "vendor_product_code": (rs.%Get("vendor_product_code")),
                    "date_arrival": (rs.%Get("date_arrival")),
                    "quantity_kg": (rs.%Get("quantity_kg"))
      })
    }
    Set itemsobj = {}
    Set itemsobj."rowcount" = rs.%ROWCOUNT
    Set itemsobj."items" = itemsarray
    Write itemsobj.%ToJSON()
  }
  Catch (oException) {
    Set expobj = {}
    Set expobj."exception" = oException
    Write expobj.%ToJSON()
  }
  Quit $$$OK
}

}
