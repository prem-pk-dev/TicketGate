export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      add_ons: {
        Row: {
          description: string | null
          event_id: string | null
          id: string
          is_active: boolean
          name: string
          price: number
        }
        Insert: {
          description?: string | null
          event_id?: string | null
          id?: string
          is_active?: boolean
          name: string
          price: number
        }
        Update: {
          description?: string | null
          event_id?: string | null
          id?: string
          is_active?: boolean
          name?: string
          price?: number
        }
        Relationships: [
          {
            foreignKeyName: "add_ons_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
        ]
      }
      booking_add_ons: {
        Row: {
          add_on_id: string
          booking_id: string
          id: string
          quantity: number
          unit_price: number
        }
        Insert: {
          add_on_id: string
          booking_id: string
          id?: string
          quantity?: number
          unit_price: number
        }
        Update: {
          add_on_id?: string
          booking_id?: string
          id?: string
          quantity?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "booking_add_ons_add_on_id_fkey"
            columns: ["add_on_id"]
            isOneToOne: false
            referencedRelation: "add_ons"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "booking_add_ons_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
        ]
      }
      booking_seats: {
        Row: {
          booking_id: string
          id: string
          price: number
          show_seat_id: string
        }
        Insert: {
          booking_id: string
          id?: string
          price: number
          show_seat_id: string
        }
        Update: {
          booking_id?: string
          id?: string
          price?: number
          show_seat_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "booking_seats_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "booking_seats_show_seat_id_fkey"
            columns: ["show_seat_id"]
            isOneToOne: false
            referencedRelation: "public_show_seats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "booking_seats_show_seat_id_fkey"
            columns: ["show_seat_id"]
            isOneToOne: false
            referencedRelation: "show_seats"
            referencedColumns: ["id"]
          },
        ]
      }
      bookings: {
        Row: {
          booking_code: string
          created_at: string
          discount: number
          expires_at: string | null
          fees: number
          id: string
          promo_code_id: string | null
          qr_token: string
          show_id: string
          status: Database["public"]["Enums"]["booking_status"]
          subtotal: number
          total: number
          user_id: string
        }
        Insert: {
          booking_code?: string
          created_at?: string
          discount?: number
          expires_at?: string | null
          fees?: number
          id?: string
          promo_code_id?: string | null
          qr_token?: string
          show_id: string
          status?: Database["public"]["Enums"]["booking_status"]
          subtotal?: number
          total?: number
          user_id: string
        }
        Update: {
          booking_code?: string
          created_at?: string
          discount?: number
          expires_at?: string | null
          fees?: number
          id?: string
          promo_code_id?: string | null
          qr_token?: string
          show_id?: string
          status?: Database["public"]["Enums"]["booking_status"]
          subtotal?: number
          total?: number
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "bookings_promo_code_id_fkey"
            columns: ["promo_code_id"]
            isOneToOne: false
            referencedRelation: "promo_codes"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_show_id_fkey"
            columns: ["show_id"]
            isOneToOne: false
            referencedRelation: "shows"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bookings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      check_ins: {
        Row: {
          booking_id: string
          checked_in_at: string
          checked_in_by: string | null
          id: string
        }
        Insert: {
          booking_id: string
          checked_in_at?: string
          checked_in_by?: string | null
          id?: string
        }
        Update: {
          booking_id?: string
          checked_in_at?: string
          checked_in_by?: string | null
          id?: string
        }
        Relationships: [
          {
            foreignKeyName: "check_ins_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: true
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "check_ins_checked_in_by_fkey"
            columns: ["checked_in_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      cities: {
        Row: {
          id: string
          is_active: boolean
          name: string
          slug: string
          state: string
        }
        Insert: {
          id?: string
          is_active?: boolean
          name: string
          slug: string
          state: string
        }
        Update: {
          id?: string
          is_active?: boolean
          name?: string
          slug?: string
          state?: string
        }
        Relationships: []
      }
      events: {
        Row: {
          age_rating: string | null
          banner_url: string | null
          category: string
          created_at: string
          description: string | null
          duration_minutes: number | null
          id: string
          language: string | null
          organizer_id: string | null
          poster_url: string | null
          slug: string
          status: string
          title: string
          updated_at: string
        }
        Insert: {
          age_rating?: string | null
          banner_url?: string | null
          category: string
          created_at?: string
          description?: string | null
          duration_minutes?: number | null
          id?: string
          language?: string | null
          organizer_id?: string | null
          poster_url?: string | null
          slug: string
          status?: string
          title: string
          updated_at?: string
        }
        Update: {
          age_rating?: string | null
          banner_url?: string | null
          category?: string
          created_at?: string
          description?: string | null
          duration_minutes?: number | null
          id?: string
          language?: string | null
          organizer_id?: string | null
          poster_url?: string | null
          slug?: string
          status?: string
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "events_organizer_id_fkey"
            columns: ["organizer_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      halls: {
        Row: {
          id: string
          name: string
          seat_columns: number
          seat_rows: number
          venue_id: string
        }
        Insert: {
          id?: string
          name: string
          seat_columns?: number
          seat_rows?: number
          venue_id: string
        }
        Update: {
          id?: string
          name?: string
          seat_columns?: number
          seat_rows?: number
          venue_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "halls_venue_id_fkey"
            columns: ["venue_id"]
            isOneToOne: false
            referencedRelation: "venues"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          booking_id: string
          created_at: string
          id: string
          idempotency_key: string
          provider: string
          provider_reference: string | null
          status: Database["public"]["Enums"]["payment_status"]
        }
        Insert: {
          amount: number
          booking_id: string
          created_at?: string
          id?: string
          idempotency_key: string
          provider?: string
          provider_reference?: string | null
          status?: Database["public"]["Enums"]["payment_status"]
        }
        Update: {
          amount?: number
          booking_id?: string
          created_at?: string
          id?: string
          idempotency_key?: string
          provider?: string
          provider_reference?: string | null
          status?: Database["public"]["Enums"]["payment_status"]
        }
        Relationships: [
          {
            foreignKeyName: "payments_booking_id_fkey"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          full_name: string | null
          id: string
          phone: string | null
          role: Database["public"]["Enums"]["app_role"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          full_name?: string | null
          id: string
          phone?: string | null
          role?: Database["public"]["Enums"]["app_role"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          full_name?: string | null
          id?: string
          phone?: string | null
          role?: Database["public"]["Enums"]["app_role"]
          updated_at?: string
        }
        Relationships: []
      }
      promo_codes: {
        Row: {
          code: string
          discount_amount: number | null
          discount_percent: number | null
          id: string
          is_active: boolean
          max_uses: number | null
          min_order: number
          used_count: number
          valid_from: string
          valid_until: string | null
        }
        Insert: {
          code: string
          discount_amount?: number | null
          discount_percent?: number | null
          id?: string
          is_active?: boolean
          max_uses?: number | null
          min_order?: number
          used_count?: number
          valid_from?: string
          valid_until?: string | null
        }
        Update: {
          code?: string
          discount_amount?: number | null
          discount_percent?: number | null
          id?: string
          is_active?: boolean
          max_uses?: number | null
          min_order?: number
          used_count?: number
          valid_from?: string
          valid_until?: string | null
        }
        Relationships: []
      }
      seats: {
        Row: {
          base_price: number
          category: string
          hall_id: string
          id: string
          row_label: string
          seat_number: number
        }
        Insert: {
          base_price?: number
          category?: string
          hall_id: string
          id?: string
          row_label: string
          seat_number: number
        }
        Update: {
          base_price?: number
          category?: string
          hall_id?: string
          id?: string
          row_label?: string
          seat_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "seats_hall_id_fkey"
            columns: ["hall_id"]
            isOneToOne: false
            referencedRelation: "halls"
            referencedColumns: ["id"]
          },
        ]
      }
      show_seats: {
        Row: {
          booking_id: string | null
          id: string
          locked_by: string | null
          locked_until: string | null
          price: number
          seat_id: string
          show_id: string
          status: Database["public"]["Enums"]["show_seat_status"]
        }
        Insert: {
          booking_id?: string | null
          id?: string
          locked_by?: string | null
          locked_until?: string | null
          price: number
          seat_id: string
          show_id: string
          status?: Database["public"]["Enums"]["show_seat_status"]
        }
        Update: {
          booking_id?: string | null
          id?: string
          locked_by?: string | null
          locked_until?: string | null
          price?: number
          seat_id?: string
          show_id?: string
          status?: Database["public"]["Enums"]["show_seat_status"]
        }
        Relationships: [
          {
            foreignKeyName: "show_seats_booking_fk"
            columns: ["booking_id"]
            isOneToOne: false
            referencedRelation: "bookings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "show_seats_locked_by_fkey"
            columns: ["locked_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "show_seats_seat_id_fkey"
            columns: ["seat_id"]
            isOneToOne: false
            referencedRelation: "seats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "show_seats_show_id_fkey"
            columns: ["show_id"]
            isOneToOne: false
            referencedRelation: "shows"
            referencedColumns: ["id"]
          },
        ]
      }
      shows: {
        Row: {
          ends_at: string
          event_id: string
          hall_id: string
          id: string
          sales_open: boolean
          starts_at: string
        }
        Insert: {
          ends_at: string
          event_id: string
          hall_id: string
          id?: string
          sales_open?: boolean
          starts_at: string
        }
        Update: {
          ends_at?: string
          event_id?: string
          hall_id?: string
          id?: string
          sales_open?: boolean
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shows_event_id_fkey"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shows_hall_id_fkey"
            columns: ["hall_id"]
            isOneToOne: false
            referencedRelation: "halls"
            referencedColumns: ["id"]
          },
        ]
      }
      venues: {
        Row: {
          address: string
          city_id: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          name: string
          slug: string
        }
        Insert: {
          address: string
          city_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          name: string
          slug: string
        }
        Update: {
          address?: string
          city_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          name?: string
          slug?: string
        }
        Relationships: [
          {
            foreignKeyName: "venues_city_id_fkey"
            columns: ["city_id"]
            isOneToOne: false
            referencedRelation: "cities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "venues_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      public_show_seats: {
        Row: {
          category: string | null
          id: string | null
          is_locked: boolean | null
          price: number | null
          row_label: string | null
          seat_id: string | null
          seat_number: number | null
          show_id: string | null
          status: Database["public"]["Enums"]["show_seat_status"] | null
        }
        Relationships: [
          {
            foreignKeyName: "show_seats_seat_id_fkey"
            columns: ["seat_id"]
            isOneToOne: false
            referencedRelation: "seats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "show_seats_show_id_fkey"
            columns: ["show_id"]
            isOneToOne: false
            referencedRelation: "shows"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      cancel_booking: { Args: { p_booking_id: string }; Returns: Json }
      confirm_dummy_payment: {
        Args: {
          p_booking_id: string
          p_idempotency_key: string
          p_success: boolean
        }
        Returns: Json
      }
      create_booking: {
        Args: {
          p_add_on_ids?: string[]
          p_promo_code?: string
          p_seat_ids: string[]
          p_show_id: string
        }
        Returns: Json
      }
      current_user_role: {
        Args: never
        Returns: Database["public"]["Enums"]["app_role"]
      }
      lock_show_seats: {
        Args: { p_seat_ids: string[]; p_show_id: string }
        Returns: Json
      }
      release_expired_seat_locks: { Args: never; Returns: number }
      set_user_role: {
        Args: {
          p_role: Database["public"]["Enums"]["app_role"]
          p_user_id: string
        }
        Returns: Json
      }
      validate_ticket: { Args: { p_qr_token: string }; Returns: Json }
    }
    Enums: {
      app_role: "USER" | "ORGANIZER" | "ADMIN"
      booking_status:
        | "PENDING"
        | "CONFIRMED"
        | "CANCELLED"
        | "EXPIRED"
        | "REFUNDED"
      payment_status: "INITIATED" | "SUCCESS" | "FAILED" | "REFUNDED"
      show_seat_status: "AVAILABLE" | "LOCKED" | "BOOKED"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["USER", "ORGANIZER", "ADMIN"],
      booking_status: [
        "PENDING",
        "CONFIRMED",
        "CANCELLED",
        "EXPIRED",
        "REFUNDED",
      ],
      payment_status: ["INITIATED", "SUCCESS", "FAILED", "REFUNDED"],
      show_seat_status: ["AVAILABLE", "LOCKED", "BOOKED"],
    },
  },
} as const
