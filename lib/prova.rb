#!/usr/bin/env ruby

require './micro_macro.rb'

a="pippo e %{chi}% vanno %{dove}%"

puts Micro_Macro.expand(a,
                        :macros => {
                          'chi' => 'minnie e %{cugino}%',
                          'dove' => 'a casa',
                          'cugino' => 'topolino'
                        })
                        
