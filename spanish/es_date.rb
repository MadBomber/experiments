#!/usr/bin/env ruby
##########################################################
###
##  File: es_date.rb
##  Desc: Spanish wrapper on the Date class
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'awesome_print'
require 'pp'
require 'date'

class EsDate < Date

  DAYNAMES = %w{
    Domingo Lunes Martes Miércoles Jueves Viernes Sábado
  } # Sunday .. Saturday

  ABBR_DAYNAMES = %w{
    Dom Lun Mar Mié Jue Vie Sab
  } # Sun .. Sat

  MONTHNAMES = %w{
    Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre
  } # January .. December

  ABBR_MONTHNAMES = %w{
    Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic
  } # Jan .. Dec

end # end of class EsDate < Date

puts Date.today.strftime("%A, %d de %B de %Y")


puts EsDate.today.strftime("%A, %d de %B de %Y")





